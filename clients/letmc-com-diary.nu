# Auto-generated client for agentOS API V3, Diary Call Group vv3-diary
# Source: https://api.apis.guru/v2/specs/letmc.com/diary/v3-diary/openapi.json
# Auth: --token flag or $env.AGENTOS_API_V3_DIARY_CALL_GROUP_TOKEN

const BASE_URL = "https://live-api.letmc.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AGENTOS_API_V3_DIARY_CALL_GROUP_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "apikey" => { {scheme: $scheme, headers: {ApiKey: $token_val}, query: "", location: "header"} }
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://live-api.letmc.com"] }
def auth-scheme-completer [] { ["apikey" "basic" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def accept-completer-1 [] { ["application/json" "text/json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "diary-allocations get-controller" } } | get name | first)
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

# Get a list of all available allocations for a date + 7 days for a specified appointment type
#
# GET /v3/diary/{shortName}/allocations
# operationId: DiaryController_GetAllocations
export def "diary-allocations get-controller" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --preferred-date: string # The date to search from (format: date-time)
  --appointment-type: string # The unique appointment type identifier
  --lettings: oneof<nothing, bool> # Sales or Lettings property?
  --property-identifier: string # The unique property identifier (Sales or Lettings) determines branch and property type
  --branch-id: string # Branch ID to check appointments (required if no property submitted)
]: nothing -> table<End: string, StaffID: string, StaffName: string, Start: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  let qp = [(serialize-qp "preferredDate" $preferred_date "scalar") (serialize-qp "appointmentType" $appointment_type "scalar") (serialize-qp "lettings" $lettings "scalar") (serialize-qp "propertyIdentifier" $property_identifier "scalar") (serialize-qp "branchID" $branch_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/allocations") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"preferredDate": $preferred_date, "appointmentType": $appointment_type, "lettings": $lettings, "propertyIdentifier": $property_identifier, "branchID": $branch_id} | compact), body: null}
}

# Delete an existing appointment using its unique identifier
#
# DELETE /v3/diary/{shortName}/appointment
# operationId: DiaryController_DeleteAppointment
export def "diary-appointment delete-controller" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --appointment-id: string # The unique appointment id
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  let qp = [(serialize-qp "appointmentID" $appointment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/appointment") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"appointmentID": $appointment_id} | compact), body: null}
}

# Get an appointment by ID
#
# GET /v3/diary/{shortName}/appointment
# operationId: DiaryController_GetAppointment
export def "diary-appointment get-controller" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --appointment-id: string # Appointment ID
]: nothing -> record<AppointmentType: string, Cancelled: bool, Comment: string, CreatedAt: string, CreatedBy: string, ETag: string, End: string, LinkedProperties: table<Address1: string, Address2: string, Address3: string, Address4: string, AddressFlatRoomNumber: string, AddressNumber: string, ETag: string, LatestTenancy: record, MainLandlord: record, OID: string, Postcode: string>, NextRecurringDate: string, OID: string, Recurrence: int, RecurrenceType: string, RemindAt: string, RemindBefore: string, Staff: string, Start: string, Subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  let qp = [(serialize-qp "appointmentID" $appointment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/appointment") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"appointmentID": $appointment_id} | compact), body: null}
}

# Post an appointment into a valid diary allocation
#
# POST /v3/diary/{shortName}/appointment
# operationId: DiaryController_PostAppointment
# --AllocationDetails shape: {End?: string, StaffID?: string, StaffName?: string, Start?: string}
# --Guests item shape: {AllowMarketingCorrespondence?: bool, EmailAddress?: string, Forename?: string, MobilePhone?: string, OID?: string, Surname?: string}
export def "diary-appointment create-controller" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --property-identifier: list<string> # The unique property identifier (Sales or Lettings)
  --lettings: oneof<nothing, bool> # Sales or Lettings property?
  --allocation-details: record # Represents a viewing booking slot — shape: {End?: string, StaffID?: string, StaffName?: string, Start?: string}
  --appointment-type: string # The Appointment Type ID
  --extra-comments: string # Additional appointment comments
  --guests: list # A collection of guests linked to the appointment. If none leave empty — item shape: {AllowMarketingCorrespondence?: bool, EmailAddress?: string, Forename?: string, MobilePhone?: string, OID?: string, Surname?: string}
  --subject: string # The subject of the appointment
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  let qp = [(serialize-qp "propertyIdentifier" $property_identifier "multi") (serialize-qp "lettings" $lettings "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/appointment") $qp)
  let req_body = {"AllocationDetails": $allocation_details, "AppointmentType": $appointment_type, "ExtraComments": $extra_comments, "Guests": $guests, "Subject": $subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"propertyIdentifier": $property_identifier, "lettings": $lettings} | compact), body: $req_body}
}

# Update an existing appointment using its unique identifier
#
# PUT /v3/diary/{shortName}/appointment
# operationId: DiaryController_PutAppointment
# --AllocationDetails shape: {End?: string, StaffID?: string, StaffName?: string, Start?: string}
# --Guests item shape: {AllowMarketingCorrespondence?: bool, EmailAddress?: string, Forename?: string, MobilePhone?: string, OID?: string, Surname?: string}
export def "diary-appointment update-controller" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --appointment-id: string # The unique appointment id
  --lettings: oneof<nothing, bool> # Sales or Lettings property?
  --allow-marketing-correspondence: oneof<nothing, bool> # Sales or Lettings property?
  --allocation-details: record # Represents a viewing booking slot — shape: {End?: string, StaffID?: string, StaffName?: string, Start?: string}
  --appointment-type: string # The Appointment Type ID
  --extra-comments: string # Additional appointment comments
  --guests: list # A collection of guests linked to the appointment. If none leave empty — item shape: {AllowMarketingCorrespondence?: bool, EmailAddress?: string, Forename?: string, MobilePhone?: string, OID?: string, Surname?: string}
  --subject: string # The subject of the appointment
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  let qp = [(serialize-qp "appointmentID" $appointment_id "scalar") (serialize-qp "lettings" $lettings "scalar") (serialize-qp "AllowMarketingCorrespondence" $allow_marketing_correspondence "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/appointment") $qp)
  let req_body = {"AllocationDetails": $allocation_details, "AppointmentType": $appointment_type, "ExtraComments": $extra_comments, "Guests": $guests, "Subject": $subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"appointmentID": $appointment_id, "lettings": $lettings, "AllowMarketingCorrespondence": $allow_marketing_correspondence} | compact), body: $req_body}
}

# Submit appointment feedback
#
# POST /v3/diary/{shortName}/appointment/feedback
# operationId: DiaryController_AddFeedback
export def "diary-appointment-feedback create-controller" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --appointment-id: string # Appointment to submit feedback to:-
  --feedback: string # Feedback to submit:-
  --property-id: string # Property to submit feedback to:-
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/appointment/feedback"))
  let req_body = {"AppointmentID": $appointment_id, "Feedback": $feedback, "PropertyID": $property_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Cancel an existing appointment using its unique identifier
#
# PATCH /v3/diary/{shortName}/appointment/{appointmentID}/cancel
# operationId: DiaryController_CancelAppointment
export def "diary-appointment-cancel cancel-controller" [
  short_name: string
  appointment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  if ($appointment_id | is-empty) { error make --unspanned { msg: "path parameter 'appointmentID' must be non-empty" } }
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), appointment_id: (encode-path-segment $appointment_id)} | format pattern "/v3/diary/{short_name}/appointment/{appointment_id}/cancel"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# A collection of diary appointments linked to a company filtered between specific dates and by appointment type
#
# GET /v3/diary/{shortName}/appointmentsbetweendates
# operationId: DiaryController_GetAppointmentsBetweenDates
export def "diary-appointmentsbetweendates get-controller-appointments-between-dates" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --branch-id: string # The unique ID of the Branch
  --start-date: string # The search from date (format: date-time)
  --end-date: string # The search to date (format: date-time)
  --appointment-types-to-search: list<string> # The appointment IDs to search for
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<AppointmentType: string, Cancelled: bool, Comment: string, CreatedAt: string, CreatedBy: string, ETag: string, End: string, LinkedProperties: list, NextRecurringDate: string, OID: string, Recurrence: int, RecurrenceType: string, RemindAt: string, RemindBefore: string, Staff: string, Start: string, Subject: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  let qp = [(serialize-qp "branchID" $branch_id "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "appointmentTypesToSearch" $appointment_types_to_search "multi") (serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/appointmentsbetweendates") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"branchID": $branch_id, "startDate": $start_date, "endDate": $end_date, "appointmentTypesToSearch": $appointment_types_to_search, "offset": $offset, "count": $count} | compact), body: null}
}

# A collection of all diary appointment types
#
# GET /v3/diary/{shortName}/appointmenttypes
# operationId: DiaryController_GetAppointmentTypes
export def "diary-appointmenttypes get-controller-appointment-types" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<ETag: string, Name: string, OID: string, SystemType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/appointmenttypes") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"offset": $offset, "count": $count} | compact), body: null}
}

# All branches defined for a company
#
# GET /v3/diary/{shortName}/company/branches
# operationId: CompanyController_GetBranches
export def "diary-company-branches get-controller" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/company/branches") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"offset": $offset, "count": $count} | compact), body: null}
}

# Get a specific branch given its unique Object ID (OID)
#
# GET /v3/diary/{shortName}/company/branches/{branchID}
export def "diary-company-branches get" [
  short_name: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  if ($branch_id | is-empty) { error make --unspanned { msg: "path parameter 'branchID' must be non-empty" } }
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), branch_id: (encode-path-segment $branch_id)} | format pattern "/v3/diary/{short_name}/company/branches/{branch_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves all recurring appointments:-
#
# GET /v3/diary/{shortName}/recurringappointment
# operationId: DiaryController_GetRecurringAppointments
export def "diary-recurringappointment get-controller-recurring-appointments" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --branch-id: string # The unique ID of the Branch
  --appointment-types-to-search: list<string> # The appointment IDs to search for
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<AppointmentType: string, Cancelled: bool, Comment: string, CreatedAt: string, CreatedBy: string, ETag: string, End: string, LinkedProperties: list, NextRecurringDate: string, OID: string, Recurrence: int, RecurrenceType: string, RemindAt: string, RemindBefore: string, Staff: string, Start: string, Subject: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  let qp = [(serialize-qp "branchID" $branch_id "scalar") (serialize-qp "appointmentTypesToSearch" $appointment_types_to_search "multi") (serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/recurringappointment") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"branchID": $branch_id, "appointmentTypesToSearch": $appointment_types_to_search, "offset": $offset, "count": $count} | compact), body: null}
}

# Match Guest Parameters with existing applicants
#
# GET /v3/diary/{shortname}/{branchID}/guest/search
# operationId: DiaryController_SearchGuest
export def "diary-guest-search list-controller" [
  shortname: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --forename: string
  --emailaddress: string
  --surname: string
  --offset: int # format: int32
  --count: int # format: int32
]: nothing -> record<Count: int, Data: table<ContactMobile: string, EmailAddress: string, Forename: string, OID: string, Surname: string>, Links: table<Href: string, Method: string, Relationship: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($shortname | is-empty) { error make --unspanned { msg: "path parameter 'shortname' must be non-empty" } }
  if ($branch_id | is-empty) { error make --unspanned { msg: "path parameter 'branchID' must be non-empty" } }
  let qp = [(serialize-qp "forename" $forename "scalar") (serialize-qp "emailaddress" $emailaddress "scalar") (serialize-qp "surname" $surname "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({shortname: (encode-path-segment $shortname), branch_id: (encode-path-segment $branch_id)} | format pattern "/v3/diary/{shortname}/{branch_id}/guest/search") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"forename": $forename, "emailaddress": $emailaddress, "surname": $surname, "offset": $offset, "count": $count} | compact), body: null}
}
