# Auto-generated client for OnSched Consumer API vv1
# Source: https://api.apis.guru/v2/specs/onsched.com/consumer/v1/openapi.json
# Auth: --token flag or $env.ONSCHED_CONSUMER_API_TOKEN

const BASE_URL = "https://sandbox-api.onsched.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ONSCHED_CONSUMER_API_TOKEN | default "" }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://sandbox-api.onsched.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def scope-completer [] { ["all" "company" "location"] }
def sort-order-completer [] { ["name" "natural"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location
  --email: string # Filter by email address
  --lastname: string # Filter by lastname or part of it
  --phone: string # Filter by phone number or part of it
  --service-id: string # Filter by service
  --calendar-id: string # Filter by calendar
  --resource-id: string # Filter by resource
  --customer-id: string # Filter by customer
  --service-allocation-id: string # Filter by service allocation
  --start-date: string # Format YYYY-MM-DD. Filter by on/after startDate (format: date-time)
  --end-date: string # Format YYYY-MM-DD. Filter on/before endDate (format: date-time)
  --status: string # Filter by status: IN, BK, CN, RE, RS
  --booked-by: string # Filter by the email of who booked
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit, default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<auditTrail: list, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: list, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: list, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "lastname" $lastname "scalar") (serialize-qp "phone" $phone "scalar") (serialize-qp "serviceId" $service_id "scalar") (serialize-qp "calendarId" $calendar_id "scalar") (serialize-qp "resourceId" $resource_id "scalar") (serialize-qp "customerId" $customer_id "scalar") (serialize-qp "serviceAllocationId" $service_allocation_id "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "bookedBy" $booked_by "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/appointments" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locationId": $location_id, "email": $email, "lastname": $lastname, "phone": $phone, "serviceId": $service_id, "calendarId": $calendar_id, "resourceId": $resource_id, "customerId": $customer_id, "serviceAllocationId": $service_allocation_id, "startDate": $start_date, "endDate": $end_date, "status": $status, "bookedBy": $booked_by, "offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create Appointment
#
# POST /consumer/v1/appointments
# --appointmentBookingFields item shape: {name?: string, value?: string}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
# --customerBookingFields item shape: {name?: string, value?: string}
export def "consumer-appointments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --complete-booking: string # Options are "BK", "RS" or "IN"
  --appointment-booking-fields: list # nullable — item shape: {name?: string, value?: string}
  --booked-by: string # nullable
  --booking-window-id: string # nullable
  --calendar-id: string # nullable
  --custom-fields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --customer-booking-fields: list # nullable — item shape: {name?: string, value?: string}
  --customer-id: string # nullable
  --customer-message: string # nullable
  --email: string # nullable
  --end-date-time: string # format: date-time
  --group-size: int # nullable, format: int32
  --location: string # nullable
  --location-id: string # nullable
  --name: string # nullable
  --notes: string # nullable
  --phone: string # nullable
  --phone-type: string # nullable
  --resource-group-id: string # nullable
  --resource-id: string # nullable
  --resource-ids: string # nullable
  --service-allocation-id: string # nullable
  --service-id: string # nullable
  --start-date-time: string # format: date-time
  --timezone-name: string # nullable
  --travel-appointment-id: string # nullable
  --travel-time-mins: int # format: int32
]: any -> record<appointmentBookingFields: table<businessId: string, companyId: string, fieldLabel: string, fieldLength: int, fieldListItems: list, fieldName: string, fieldRequired: bool, fieldType: string, id: string, leadQuestion: bool, leadQuestionWeight: float, object: string, sortKey: int>, auditTrail: table<appointmentId: string, id: string, modificationType: string, modifiedBy: string, modifiedOn: string, notesAfter: string, notesBefore: string, statusAfter: string, statusBefore: string>, bookedBy: string, bookingForms: record<bookingConfirmationPage: string, bookingForm: string>, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerBookingFields: table<businessId: string, companyId: string, fieldLabel: string, fieldLength: int, fieldListItems: list, fieldName: string, fieldRequired: bool, fieldType: string, id: string, leadQuestion: bool, leadQuestionWeight: float, object: string, sortKey: int>, customerId: string, customerMessage: string, customers: table<appointmentId: string, customerId: string>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: table<appointmentId: string, resourceEmail: string, resourceGroupId: string, resourceId: string, resourceImageUrl: string, resourceName: string>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "completeBooking" $complete_booking "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/appointments" $qp $auth.query)
  let req_body = {"appointmentBookingFields": $appointment_booking_fields, "bookedBy": $booked_by, "bookingWindowId": $booking_window_id, "calendarId": $calendar_id, "customFields": $custom_fields, "customerBookingFields": $customer_booking_fields, "customerId": $customer_id, "customerMessage": $customer_message, "email": $email, "endDateTime": $end_date_time, "groupSize": $group_size, "location": $location, "locationId": $location_id, "name": $name, "notes": $notes, "phone": $phone, "phoneType": $phone_type, "resourceGroupId": $resource_group_id, "resourceId": $resource_id, "resourceIds": $resource_ids, "serviceAllocationId": $service_allocation_id, "serviceId": $service_id, "startDateTime": $start_date_time, "timezoneName": $timezone_name, "travelAppointmentId": $travel_appointment_id, "travelTimeMins": $travel_time_mins} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"completeBooking": $complete_booking} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location
]: nothing -> record<bookingFields: table<businessId: string, companyId: string, fieldLabel: string, fieldLength: int, fieldListItems: list, fieldName: string, fieldRequired: bool, fieldType: string, id: string, leadQuestion: bool, leadQuestionWeight: float, object: string, sortKey: int>, object: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $location_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/appointments/bookingfields" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locationId": $location_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location
]: nothing -> record<customFields: table<fieldKey: string, fieldLabel: string, fieldLength: int, fieldListItems: list, fieldName: string, fieldPublic: bool, fieldRequired: bool, fieldType: string, id: string, leadQuestion: bool, leadQuestionWeight: float, object: string, sortKey: int>, object: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $location_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/appointments/customfields" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locationId": $location_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<auditTrail: table<appointmentId: string, id: string, modificationType: string, modifiedBy: string, modifiedOn: string, notesAfter: string, notesBefore: string, statusAfter: string, statusBefore: string>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: table<appointmentId: string, customerId: string>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: table<appointmentId: string, resourceEmail: string, resourceGroupId: string, resourceId: string, resourceImageUrl: string, resourceName: string>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/appointments/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<auditTrail: table<appointmentId: string, id: string, modificationType: string, modifiedBy: string, modifiedOn: string, notesAfter: string, notesBefore: string, statusAfter: string, statusBefore: string>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: table<appointmentId: string, customerId: string>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: table<appointmentId: string, resourceEmail: string, resourceGroupId: string, resourceId: string, resourceImageUrl: string, resourceName: string>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/appointments/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Book Appointment
#
# PUT /consumer/v1/appointments/{id}/book
# --appointmentBookingFields item shape: {name?: string, value?: string}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
# --customerBookingFields item shape: {name?: string, value?: string}
export def "consumer-appointments-book update" [
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
  --appointment-booking-fields: list # nullable — item shape: {name?: string, value?: string}
  --custom-fields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --customer-booking-fields: list # nullable — item shape: {name?: string, value?: string}
  --customer-message: string # nullable
  --email: string # nullable
  --group-size: int # nullable, format: int32
  --name: string # nullable
  --notes: string # nullable
  --phone: string # nullable
  --phone-ext: string # nullable
  --phone-type: string # nullable
]: any -> record<auditTrail: table<appointmentId: string, id: string, modificationType: string, modifiedBy: string, modifiedOn: string, notesAfter: string, notesBefore: string, statusAfter: string, statusBefore: string>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: table<appointmentId: string, customerId: string>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: table<appointmentId: string, resourceEmail: string, resourceGroupId: string, resourceId: string, resourceImageUrl: string, resourceName: string>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/appointments/{id}/book") $auth.query)
  let req_body = {"appointmentBookingFields": $appointment_booking_fields, "customFields": $custom_fields, "customerBookingFields": $customer_booking_fields, "customerMessage": $customer_message, "email": $email, "groupSize": $group_size, "name": $name, "notes": $notes, "phone": $phone, "phoneExt": $phone_ext, "phoneType": $phone_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Cancel Appointment
#
# PUT /consumer/v1/appointments/{id}/cancel
export def "consumer-appointments-cancel update" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/appointments/{id}/cancel") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Confirm Appointment
#
# PUT /consumer/v1/appointments/{id}/confirm
export def "consumer-appointments-confirm update" [
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
  --undo: oneof<nothing, bool> # Use this parameter to undo the confirmed status
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "undo" $undo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/appointments/{id}/confirm") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"undo": $undo} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Set NoShow Status
#
# PUT /consumer/v1/appointments/{id}/noshow
export def "consumer-appointments-noshow update" [
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
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/appointments/{id}/noshow") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Reschedule Appointment
#
# PUT /consumer/v1/appointments/{id}/reschedule
export def "consumer-appointments-reschedule update" [
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
  --end-date-time: string # format: date-time
  --resource-id: string # nullable
  --resource-ids: string # nullable
  --service-id: string # nullable
  --start-date-time: string # format: date-time
  --travel-appointment-id: string # nullable
  --travel-time-mins: int # format: int32
]: any -> record<auditTrail: table<appointmentId: string, id: string, modificationType: string, modifiedBy: string, modifiedOn: string, notesAfter: string, notesBefore: string, statusAfter: string, statusBefore: string>, bookedBy: string, businessName: string, calendarId: string, confirmationNumber: string, confirmed: bool, createDate: string, customFields: record, customerId: string, customerMessage: string, customers: table<appointmentId: string, customerId: string>, date: string, dateInternational: string, downloadIcsUrl: string, duration: int, email: string, emailConfirmationSent: string, emailReminderSent: string, endDateTime: string, firstname: string, groupSize: int, id: string, ipAddress: string, lastModifiedBy: string, lastModifiedOn: string, lastname: string, latitude: string, location: string, locationId: string, longitude: string, name: string, notes: string, object: string, onlineBooking: bool, paymentStatus: int, phone: string, phoneExt: string, phoneType: string, rescheduledId: string, resourceEmail: string, resourceGroupId: string, resourceGroupName: string, resourceId: string, resourceImageUrl: string, resourceName: string, resources: table<appointmentId: string, resourceEmail: string, resourceGroupId: string, resourceId: string, resourceImageUrl: string, resourceName: string>, serviceAllocationId: string, serviceId: string, serviceImageUrl: string, serviceName: string, smsConfirmationSent: string, smsReminderSent: string, startDateTime: string, status: string, stripeChargeId: string, stripeRefundId: string, time: int, timezone: int, timezoneIana: string, timezoneId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/appointments/{id}/reschedule") $auth.query)
  let req_body = {"endDateTime": $end_date_time, "resourceId": $resource_id, "resourceIds": $resource_ids, "serviceId": $service_id, "startDateTime": $start_date_time, "travelAppointmentId": $travel_appointment_id, "travelTimeMins": $travel_time_mins} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Reserve Appointment
#
# PUT /consumer/v1/appointments/{id}/reserve
# --appointmentBookingFields item shape: {name?: string, value?: string}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
# --customerBookingFields item shape: {name?: string, value?: string}
export def "consumer-appointments-reserve update" [
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
  --send-notifications: oneof<nothing, bool>
  --appointment-booking-fields: list # nullable — item shape: {name?: string, value?: string}
  --custom-fields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --customer-booking-fields: list # nullable — item shape: {name?: string, value?: string}
  --customer-message: string # nullable
  --email: string # nullable
  --name: string # nullable
  --notes: string # nullable
  --phone: string # nullable
  --phone-ext: string # nullable
  --phone-type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "sendNotifications" $send_notifications "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/appointments/{id}/reserve") $qp $auth.query)
  let req_body = {"appointmentBookingFields": $appointment_booking_fields, "customFields": $custom_fields, "customerBookingFields": $customer_booking_fields, "customerMessage": $customer_message, "email": $email, "name": $name, "notes": $notes, "phone": $phone, "phoneExt": $phone_ext, "phoneType": $phone_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"sendNotifications": $send_notifications} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get Available Times
#
# GET /consumer/v1/availability/{serviceId}/{startDate}/{endDate}
export def "consumer-availability get" [
  service_id: string
  start_date: string
  end_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-time: int # Format Military Time Start Time for availability search. Defaults to Business Hours Start (format: int32)
  --end-time: int # Format Military Time. End Time for availability search. Defaults to Business Hours End (format: int32)
  --location-id: string # Id of business location, defaults to primary business location
  --resource-id: string # Resource Id for availability search
  --resource-group-id: string # Resource Group Id for availability search
  --resource-ids: string # Comma separated Resource Id's for availability search
  --round-robin: string # Round robin choice 0=none, 1=random, 2=balanced
  --duration: int # Duration of the service if different from default (format: int32)
  --interval: int # Booking Interval if different than the default (format: int32)
  --timezone-name: string # Requested IANA timezone Id to view availability
  --tz-offset: int # Request timezone offset to view availability (format: int32)
  --destination: string # For calculating travel based availability, requires distance scope
  --day-availability-start-date: string # Format YYYY-DD-YY: Start date for day availability, defaults to startDate (format: date-time)
  --day-availability: int # Number of days of day availability to return (format: int32)
  --first-day-available: oneof<nothing, bool> # Return available times for the first available day
]: nothing -> record<availableDays: table<available: bool, bookingCount: int, bookingLimit: int, closed: bool, date: string, object: string, reason: string, reasonCode: int>, availableTimes: table<allowableBookings: int, allowableCapacity: int, availableBookings: int, availableCapacity: int, date: string, displayTime: string, duration: int, endDateTime: string, resourceId: string, startDateTime: string, time: int, travelAppointmentId: string, travelTimeMins: int>, businessName: string, calendarId: string, calendarResourceGroupId: string, endDate: string, firstAvailableDate: string, locationId: string, object: string, resourceDescription: string, resourceId: string, resourceIds: string, resourceName: string, serviceDescription: string, serviceDuration: int, serviceId: string, serviceName: string, startDate: string, timezoneName: string, tzRequested: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  if ($start_date | is-empty) { error make --unspanned { msg: "path parameter 'startDate' must be non-empty" } }
  if ($end_date | is-empty) { error make --unspanned { msg: "path parameter 'endDate' must be non-empty" } }
  let qp = [(serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar") (serialize-qp "locationId" $location_id "scalar") (serialize-qp "resourceId" $resource_id "scalar") (serialize-qp "resourceGroupId" $resource_group_id "scalar") (serialize-qp "resourceIds" $resource_ids "scalar") (serialize-qp "roundRobin" $round_robin "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "timezoneName" $timezone_name "scalar") (serialize-qp "tzOffset" $tz_offset "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "dayAvailabilityStartDate" $day_availability_start_date "scalar") (serialize-qp "dayAvailability" $day_availability "scalar") (serialize-qp "firstDayAvailable" $first_day_available "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), start_date: (encode-path-segment $start_date), end_date: (encode-path-segment $end_date)} | format pattern "/consumer/v1/availability/{service_id}/{start_date}/{end_date}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"startTime": $start_time, "endTime": $end_time, "locationId": $location_id, "resourceId": $resource_id, "resourceGroupId": $resource_group_id, "resourceIds": $resource_ids, "roundRobin": $round_robin, "duration": $duration, "interval": $interval, "timezoneName": $timezone_name, "tzOffset": $tz_offset, "destination": $destination, "dayAvailabilityStartDate": $day_availability_start_date, "dayAvailability": $day_availability, "firstDayAvailable": $first_day_available} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Available Days
#
# GET /consumer/v1/availability/{serviceId}/{startDate}/{endDate}/days
export def "consumer-availability-days get" [
  service_id: string
  start_date: string
  end_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # Id of business location, defaults to primary business location
  --resource-id: string # Resource Id to filter on
  --tz-offset: int # Timezone offset to view availability for (format: int32)
]: nothing -> record<availableDays: table<available: bool, bookingCount: int, bookingLimit: int, closed: bool, date: string, object: string, reason: string, reasonCode: int>, object: string, resourceDescription: string, resourceId: string, resourceName: string, serviceDescription: string, serviceId: string, serviceName: string, tzRequested: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  if ($start_date | is-empty) { error make --unspanned { msg: "path parameter 'startDate' must be non-empty" } }
  if ($end_date | is-empty) { error make --unspanned { msg: "path parameter 'endDate' must be non-empty" } }
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "resourceId" $resource_id "scalar") (serialize-qp "tzOffset" $tz_offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), start_date: (encode-path-segment $start_date), end_date: (encode-path-segment $end_date)} | format pattern "/consumer/v1/availability/{service_id}/{start_date}/{end_date}/days") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locationId": $location_id, "resourceId": $resource_id, "tzOffset": $tz_offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Unavailable Times
#
# GET /consumer/v1/availability/{serviceId}/{startDate}/{endDate}/unavailable
export def "consumer-availability-unavailable get" [
  service_id: string
  start_date: string
  end_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # Id of business location, defaults to primary business location
  --resource-id: string # Resource Id to filter on
  --duration: int # Duration of the service if different from default (format: int32)
  --tz-offset: int # Request timezone offset to view unavailable times (format: int32)
  --skip-time-past-unavailability: oneof<nothing, bool> # Set as true to remove Time Past (TP) blocks in the response
]: nothing -> record<object: string, unavailableTimes: table<calendarId: string, date: string, endDateTime: string, entityId: int, entityType: string, fromTime: int, locationId: string, objectName: string, reason: string, reasonCode: string, resourceId: string, resourceName: string, serviceId: string, serviceName: string, startDateTime: string, toTime: int, tzOffset: int>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceId' must be non-empty" } }
  if ($start_date | is-empty) { error make --unspanned { msg: "path parameter 'startDate' must be non-empty" } }
  if ($end_date | is-empty) { error make --unspanned { msg: "path parameter 'endDate' must be non-empty" } }
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "resourceId" $resource_id "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "tzOffset" $tz_offset "scalar") (serialize-qp "skipTimePastUnavailability" $skip_time_past_unavailability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), start_date: (encode-path-segment $start_date), end_date: (encode-path-segment $end_date)} | format pattern "/consumer/v1/availability/{service_id}/{start_date}/{end_date}/unavailable") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locationId": $location_id, "resourceId": $resource_id, "duration": $duration, "tzOffset": $tz_offset, "skipTimePastUnavailability": $skip_time_past_unavailability} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --group-id: string # Filter by groupId
  --email: string # Filter by email address
  --lastname: string # Filter by lastname
  --deleted: oneof<nothing, bool> # Filter by deleted status
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<address: record, birthdate: string, businessName: string, companyName: string, contact: record, createdBy: string, createdOn: string, customFields: record, deletedStatus: bool, deletedTime: string, disabled: bool, email: string, emailInfo: bool, emailPromotion: bool, firstname: string, gender: string, groupId: string, id: string, inviteEmailSent: string, lastVisitDate: string, lastname: string, latitude: string, locationId: string, longitude: string, modifiedBy: string, modifiedOn: string, name: string, notificationType: string, object: string, registeredBy: string, registrationDate: string, resourceId: string, stripeCustomerId: string, subscriptionId: string, verificationDate: string, verifiedBy: string, welcomeEmailSent: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "groupId" $group_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "lastname" $lastname "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/customers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locationId": $location_id, "groupId": $group_id, "email": $email, "lastname": $lastname, "deleted": $deleted, "offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create Customer
#
# POST /consumer/v1/customers
# --address shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
# --contact shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
export def "consumer-customers create" [
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
  --contact: record # shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
  --custom-fields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --email: string # nullable
  --firstname: string # nullable
  --lastname: string # nullable
  --location-id: string # nullable
  --name: string # nullable
  --notification-type: string # 0 = default(Email), 1 = Email, 2 = SMS, 3 = Email and SMS (nullable)
  --send-lead-notification: oneof<nothing, bool>
  --stripe-customer-id: string # nullable
  --type: int # nullable, format: int32
]: any -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, birthdate: string, businessName: string, companyName: string, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, createdBy: string, createdOn: string, customFields: record, deletedStatus: bool, deletedTime: string, disabled: bool, email: string, emailInfo: bool, emailPromotion: bool, firstname: string, gender: string, groupId: string, id: string, inviteEmailSent: string, lastVisitDate: string, lastname: string, latitude: string, locationId: string, longitude: string, modifiedBy: string, modifiedOn: string, name: string, notificationType: string, object: string, registeredBy: string, registrationDate: string, resourceId: string, stripeCustomerId: string, subscriptionId: string, verificationDate: string, verifiedBy: string, welcomeEmailSent: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/consumer/v1/customers" $auth.query)
  let req_body = {"address": $address, "contact": $contact, "customFields": $custom_fields, "email": $email, "firstname": $firstname, "lastname": $lastname, "locationId": $location_id, "name": $name, "notificationType": $notification_type, "sendLeadNotification": $send_lead_notification, "stripeCustomerId": $stripe_customer_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
]: nothing -> record<bookingFields: table<businessId: string, companyId: string, fieldLabel: string, fieldLength: int, fieldListItems: list, fieldName: string, fieldRequired: bool, fieldType: string, id: string, leadQuestion: bool, leadQuestionWeight: float, object: string, sortKey: int>, object: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $location_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/customers/bookingfields" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locationId": $location_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/consumer/v1/customers/countries" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --lead-questions: oneof<nothing, bool> # A true/false indicator to filter on custom fields used for lead questions
]: nothing -> record<customFields: table<fieldKey: string, fieldLabel: string, fieldLength: int, fieldListItems: list, fieldName: string, fieldPublic: bool, fieldRequired: bool, fieldType: string, id: string, leadQuestion: bool, leadQuestionWeight: float, object: string, sortKey: int>, object: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "leadQuestions" $lead_questions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/customers/customfields" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locationId": $location_id, "leadQuestions": $lead_questions} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string
]: nothing -> table<code: string, country: string, countryName: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/customers/states" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"country": $country} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/customers/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, birthdate: string, businessName: string, companyName: string, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, createdBy: string, createdOn: string, customFields: record, deletedStatus: bool, deletedTime: string, disabled: bool, email: string, emailInfo: bool, emailPromotion: bool, firstname: string, gender: string, groupId: string, id: string, inviteEmailSent: string, lastVisitDate: string, lastname: string, latitude: string, locationId: string, longitude: string, modifiedBy: string, modifiedOn: string, name: string, notificationType: string, object: string, registeredBy: string, registrationDate: string, resourceId: string, stripeCustomerId: string, subscriptionId: string, verificationDate: string, verifiedBy: string, welcomeEmailSent: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/customers/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update Customer
#
# PUT /consumer/v1/customers/{id}
# --address shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
# --contact shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
# --customFields shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
export def "consumer-customers update" [
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
  --address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postalCode?: string, state?: string}
  --contact: record # shape: {businessPhone?: string, businessPhoneExt?: string, conferenceInfo?: string, homePhone?: string, mobilePhone?: string, preferredPhoneType?: string, skypeUsername?: string}
  --custom-fields: record # shape: {field1?: string, field10?: string, field2?: string, field3?: string, field4?: string, field5?: string, field6?: string, field7?: string, field8?: string, field9?: string}
  --email: string # nullable
  --firstname: string # nullable
  --lastname: string # nullable
  --location-id: string # nullable
  --name: string # nullable
  --notification-type: string # 0 = default(Email), 1 = Email, 2 = SMS, 3 = Email and SMS (nullable)
  --stripe-customer-id: string # nullable
  --type: int # nullable, format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/customers/{id}") $auth.query)
  let req_body = {"address": $address, "contact": $contact, "customFields": $custom_fields, "email": $email, "firstname": $firstname, "lastname": $lastname, "locationId": $location_id, "name": $name, "notificationType": $notification_type, "stripeCustomerId": $stripe_customer_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Location name (full or partial)
  --nearest-to: string # Search by distance nearest Geocoords, City, Postal/Zip Code
  --proximity: int # Maximum distance to display (format: int32)
  --units: string # Distance either imperial(miles), metric(kilometers)
  --service-id: string # Locations that offer this service
  --friendly-id: string # Frienldy Id of location
  --region-id: string # Locations within a specific region
  --ignore-primary: oneof<nothing, bool> # Don't include the Primary Location
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit, default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<address: record, adminEmail: string, adminName: string, appointmentReminders: record, businessHolidays: list, businessHours: record, companyId: string, companyName: string, defaults: record, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: list, settings: record, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record, website: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "nearestTo" $nearest_to "scalar") (serialize-qp "proximity" $proximity "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "serviceId" $service_id "scalar") (serialize-qp "friendlyId" $friendly_id "scalar") (serialize-qp "regionId" $region_id "scalar") (serialize-qp "ignorePrimary" $ignore_primary "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/locations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name, "nearestTo": $nearest_to, "proximity": $proximity, "units": $units, "serviceId": $service_id, "friendlyId": $friendly_id, "regionId": $region_id, "ignorePrimary": $ignore_primary, "offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, adminEmail: string, adminName: string, appointmentReminders: record<emailFirstReminder: int, emailFirstReminderInterval: int, emailSecondReminder: int, emailSecondReminderInterval: int, smsFirstReminder: int, smsFirstReminderInterval: int, smsSecondReminder: int, smsSecondReminderInterval: int>, businessHolidays: table<businessClosed: bool, holidayName: string, id: string, publicHolidayId: int>, businessHours: record<fri: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, mon: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sat: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, sun: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, thu: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, tue: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>, wed: record<endTime: int, is24Hours: bool, isOpen: bool, startTime: int>>, companyId: string, companyName: string, defaults: record<autoUpdateCustomer: bool, businessNotification: bool, customerCity: bool, customerState: bool, emailInfo: bool, enableUtcTimezone: bool, object: string>, email: string, fax: string, friendlyId: string, id: string, imageUrl: string, latitude: float, logo: string, longitude: float, name: string, object: string, phone: string, primaryBusiness: bool, primaryCalendarId: string, regionId: string, services: table<id: int, object: string, serviceId: int, serviceName: string>, settings: record<availabilityForm: int, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookWithAccount: bool, bookingConfirmationMessage: string, bookingMessage: string, bookingPolicy: string, bookingTimerMins: int, businessId: string, companyId: string, customerBookingsPerDay: int, customerVerification: bool, defaultService: bool, defaultToCustomerTimezone: bool, disableAuthorization: bool, enableWorldTimezones: bool, enabled: bool, familyMembersEnabled: bool, firstAvailable: bool, formFlow: int, hideBreadCrumbNav: bool, hideContinueBooking: bool, hideLocationNav: bool, hideNavBar: bool, hideServiceGroupsNav: bool, hideServicesNav: bool, id: int, lateCancelAction: int, lateCancelHours: int, lateRescheduleAction: int, lateRescheduleHours: int, liveMode: bool, locationId: string, object: string, resourceAnyLabel: string, resourceLabel: string, resourceSelection: bool, returnToAvailability: bool, returnToService: bool, serviceLabel: string, showBusinessLogo: bool, showOnSchedLogo: bool, showServiceGroups: bool>, timezoneIana: string, timezoneId: string, timezoneOffset: int, travel: record<distance: string, proximity: string, startAddress: string, startLat: string, startLon: string, units: string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/locations/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base "/consumer/v1/resourcegroups" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locationId": $location_id, "deleted": $deleted, "offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bookingNotification: int, deletedStatus: bool, deletedTime: string, description: string, email: string, id: string, locationId: string, name: string, object: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/resourcegroups/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --resource-group-id: int # Filter by groupId (format: int32)
  --email: string # Filter by email address
  --name: string # Search by name, supports Partial name search
  --sort-order: string # Specify sort order of response
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<address: record, availability: record, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record, customFields: record, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarId: string, groupId: string, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, outlookCalendarId: string, recurringAvailability: bool, services: list, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "resourceGroupId" $resource_group_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/resources" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locationId": $location_id, "resourceGroupId": $resource_group_id, "email": $email, "name": $name, "sortOrder": $sort_order, "offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record<businessPhone: string, businessPhoneExt: string, conferenceInfo: string, homePhone: string, mobilePhone: string, phoneType: string, skypeUsername: string>, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarId: string, groupId: string, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, outlookCalendarId: string, recurringAvailability: bool, services: table<object: string, resourceId: int, resourceName: string, serviceId: int, serviceName: string>, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/resources/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<object: string, resourceId: int, resourceName: string, serviceId: int, serviceName: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/resources/{id}/services") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/servicegroups" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locationId": $location_id, "offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<companyId: string, description: string, id: string, imageUrl: string, isDeleted: bool, locationId: string, name: string, object: string, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/servicegroups/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --service-group-id: int # Filter by groupId (format: int32)
  --default-service: oneof<nothing, bool> # Filter by default service, default is false
  --all-locations: oneof<nothing, bool> # Search All Locations, default is false
  --scope: string@scope-completer # Filter by scope, Company, Location or All, default is All
  --name: string # Filter by Name, supports Partial name search
  --service-id: string # Filter by ServiceId, using this parameter would ignore all other parameters
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
  --sort-order: string@sort-order-completer # Sort results using Natural Sort or Sorted alphabetically by Service Names, default is natural
  --sort-descending: oneof<nothing, bool> # Sort results in Descending Order, default true
]: nothing -> record<count: int, data: table<availability: record, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "serviceGroupId" $service_group_id "scalar") (serialize-qp "defaultService" $default_service "scalar") (serialize-qp "allLocations" $all_locations "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "serviceId" $service_id "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "sortDescending" $sort_descending "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/consumer/v1/services" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locationId": $location_id, "serviceGroupId": $service_group_id, "defaultService": $default_service, "allLocations": $all_locations, "scope": $scope, "name": $name, "serviceId": $service_id, "offset": $offset, "limit": $limit, "sortOrder": $sort_order, "sortDescending": $sort_descending} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record<frequency: string, interval: int, monthDay: string, monthType: string, weekdays: string>, repeats: bool, resourceAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, postalCode: string, state: string>, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record<businessPhone: string, businessPhoneExt: string, homePhone: string, mobilePhone: string, phoneType: string>, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/services/allocations/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<availability: record<fri: record<endTime: int, startTime: int>, mon: record<endTime: int, startTime: int>, sat: record<endTime: int, startTime: int>, sun: record<endTime: int, startTime: int>, thu: record<endTime: int, startTime: int>, tue: record<endTime: int, startTime: int>, wed: record<endTime: int, startTime: int>>, bookAheadUnit: int, bookAheadValue: int, bookInAdvance: int, bookingInterval: int, bookingLimit: int, calendarId: string, calendarResourceGroupId: string, cancellationFeeAmount: float, cancellationFeeTaxable: bool, companyId: string, consumerPadding: bool, customFields: record<field1: string, field10: string, field2: string, field3: string, field4: string, field5: string, field6: string, field7: string, field8: string, field9: string>, dailyBookingLimitCount: int, dailyBookingLimitMinutes: int, defaultService: bool, description: string, duration: int, durationInterval: int, durationMax: int, durationMin: int, durationSelect: bool, feeAmount: float, feeTaxable: bool, id: string, imageUrl: string, locationId: string, maxBookingLimit: int, maxCapacity: int, maxGroupSize: int, maxResourceBookingLimit: int, mediaPageUrl: string, name: string, nonRefundable: bool, object: string, padding: int, roundRobin: int, serviceGroupId: int, serviceGroupName: string, showOnline: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/services/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of the location, defaults to the primary location
  --resource-id: string # id of the resource to filter on
  --start-date: string # Format YYYY-MM-DD: Filter allocations on/after startDate (format: date-time)
  --end-date: string # Format YYYY-MM-DD. Filter allocations on/before endDate (format: date-time)
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<bookingCount: int, bookingLimit: int, deletedStatus: bool, deletedTime: string, endDate: string, endTime: int, id: string, locationId: string, object: string, reason: string, repeat: record, repeats: bool, resourceAddress: record, resourceDescription: string, resourceId: string, resourceImageUrl: string, resourceName: string, resourcePhone: record, serviceDescription: string, serviceDuration: int, serviceId: string, serviceImageUrl: string, serviceName: string, startDate: string, startTime: int, timezoneName: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "resourceId" $resource_id "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/services/{id}/allocations") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locationId": $location_id, "resourceId": $resource_id, "startDate": $start_date, "endDate": $end_date, "offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location-id: string # id of business location, defaults to primary business location
  --offset: int # Starting row of page, default 0 (format: int32)
  --limit: int # Page limit default 20, max 100 (format: int32)
]: nothing -> record<count: int, data: table<address: record, availability: record, bioLink: string, bookingNotification: int, calendarAvailability: int, contact: record, customFields: record, deletedStatus: bool, deletedTime: string, description: string, effectiveDate: string, email: string, gender: string, googleCalendarId: string, groupId: string, hourly: float, id: string, ignoreBusinessHours: bool, imageUrl: string, locationId: string, name: string, notificationType: int, object: string, outlookCalendarId: string, recurringAvailability: bool, services: list, skypeName: string, sortKey: int, timezoneIana: string, timezoneId: string, timezoneOffset: int>, hasMore: bool, object: string, total: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "locationId" $location_id "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/consumer/v1/services/{id}/resources") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locationId": $location_id, "offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
