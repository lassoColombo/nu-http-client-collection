# Auto-generated client for agentOS API V3, Diary Call Group vv3-diary
# Source: https://api.apis.guru/v2/specs/letmc.com/diary/v3-diary/openapi.json
# Auth: --token flag or $env.AGENTOS_API_V3_DIARY_CALL_GROUP_TOKEN

const BASE_URL = "https://live-api.letmc.com"
const DEFAULT_AUTH = "apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AGENTOS_API_V3_DIARY_CALL_GROUP_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "apikey" => { {headers: {ApiKey: $token_val}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://live-api.letmc.com"] }
def auth-scheme-completer [] { ["apikey" "basic"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def accept-completer-1 [] { ["application/json" "text/json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "diary-allocations GetAllocations" } } | get name | first)
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
export def "diary-allocations GetAllocations" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --preferredDate: string # The date to search from (format: date-time)
  --appointmentType: string # The unique appointment type identifier
  --lettings: oneof<nothing, bool> # Sales or Lettings property?
  --propertyIdentifier: string # The unique property identifier (Sales or Lettings) determines branch and property type
  --branchID: string # Branch ID to check appointments (required if no property submitted)
]: nothing -> table<End: string, StaffID: string, StaffName: string, Start: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "preferredDate" $preferredDate "scalar") (serialize-qp "appointmentType" $appointmentType "scalar") (serialize-qp "lettings" $lettings "scalar") (serialize-qp "propertyIdentifier" $propertyIdentifier "scalar") (serialize-qp "branchID" $branchID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/diary/($shortName)/allocations" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing appointment using its unique identifier
#
# DELETE /v3/diary/{shortName}/appointment
# operationId: DiaryController_DeleteAppointment
export def "diary-appointment DeleteAppointment" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --appointmentID: string # The unique appointment id
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appointmentID" $appointmentID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/diary/($shortName)/appointment" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an appointment by ID
#
# GET /v3/diary/{shortName}/appointment
# operationId: DiaryController_GetAppointment
export def "diary-appointment GetAppointment" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --appointmentID: string # Appointment ID
]: nothing -> record<AppointmentType: string, Cancelled: bool, Comment: string, CreatedAt: string, CreatedBy: string, ETag: string, End: string, LinkedProperties: table<Address1: string, Address2: string, Address3: string, Address4: string, AddressFlatRoomNumber: string, AddressNumber: string, ETag: string, LatestTenancy: record, MainLandlord: record, OID: string, Postcode: string>, NextRecurringDate: string, OID: string, Recurrence: int, RecurrenceType: string, RemindAt: string, RemindBefore: string, Staff: string, Start: string, Subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appointmentID" $appointmentID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/diary/($shortName)/appointment" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post an appointment into a valid diary allocation
#
# POST /v3/diary/{shortName}/appointment
# operationId: DiaryController_PostAppointment
# --AllocationDetails shape: {End?: string, StaffID?: string, StaffName?: string, Start?: string}
# --Guests item shape: {AllowMarketingCorrespondence?: bool, EmailAddress?: string, Forename?: string, MobilePhone?: string, OID?: string, Surname?: string}
export def "diary-appointment PostAppointment" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --propertyIdentifier: list # The unique property identifier (Sales or Lettings)
  --lettings: oneof<nothing, bool> # Sales or Lettings property?
  --AllocationDetails: record # Represents a viewing booking slot — shape: {End?: string, StaffID?: string, StaffName?: string, Start?: string}
  --AppointmentType: string # The Appointment Type ID
  --ExtraComments: string # Additional appointment comments
  --Guests: list # A collection of guests linked to the appointment. If none leave empty — item shape: {AllowMarketingCorrespondence?: bool, EmailAddress?: string, Forename?: string, MobilePhone?: string, OID?: string, Surname?: string}
  --Subject: string # The subject of the appointment
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "propertyIdentifier" $propertyIdentifier "multi") (serialize-qp "lettings" $lettings "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/diary/($shortName)/appointment" $qp)
  let body = {AllocationDetails: $AllocationDetails, AppointmentType: $AppointmentType, ExtraComments: $ExtraComments, Guests: $Guests, Subject: $Subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an existing appointment using its unique identifier
#
# PUT /v3/diary/{shortName}/appointment
# operationId: DiaryController_PutAppointment
# --AllocationDetails shape: {End?: string, StaffID?: string, StaffName?: string, Start?: string}
# --Guests item shape: {AllowMarketingCorrespondence?: bool, EmailAddress?: string, Forename?: string, MobilePhone?: string, OID?: string, Surname?: string}
export def "diary-appointment PutAppointment" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --appointmentID: string # The unique appointment id
  --lettings: oneof<nothing, bool> # Sales or Lettings property?
  --AllowMarketingCorrespondence: oneof<nothing, bool> # Sales or Lettings property?
  --AllocationDetails: record # Represents a viewing booking slot — shape: {End?: string, StaffID?: string, StaffName?: string, Start?: string}
  --AppointmentType: string # The Appointment Type ID
  --ExtraComments: string # Additional appointment comments
  --Guests: list # A collection of guests linked to the appointment. If none leave empty — item shape: {AllowMarketingCorrespondence?: bool, EmailAddress?: string, Forename?: string, MobilePhone?: string, OID?: string, Surname?: string}
  --Subject: string # The subject of the appointment
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appointmentID" $appointmentID "scalar") (serialize-qp "lettings" $lettings "scalar") (serialize-qp "AllowMarketingCorrespondence" $AllowMarketingCorrespondence "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/diary/($shortName)/appointment" $qp)
  let body = {AllocationDetails: $AllocationDetails, AppointmentType: $AppointmentType, ExtraComments: $ExtraComments, Guests: $Guests, Subject: $Subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Submit appointment feedback
#
# POST /v3/diary/{shortName}/appointment/feedback
# operationId: DiaryController_AddFeedback
export def "diary-appointment-feedback AddFeedback" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --AppointmentID: string # Appointment to submit feedback to:-
  --Feedback: string # Feedback to submit:-
  --PropertyID: string # Property to submit feedback to:-
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/diary/($shortName)/appointment/feedback")
  let body = {AppointmentID: $AppointmentID, Feedback: $Feedback, PropertyID: $PropertyID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel an existing appointment using its unique identifier
#
# PATCH /v3/diary/{shortName}/appointment/{appointmentID}/cancel
# operationId: DiaryController_CancelAppointment
export def "diary-appointment-cancel CancelAppointment" [
  shortName: string
  appointmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/diary/($shortName)/appointment/($appointmentID)/cancel")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of diary appointments linked to a company filtered between specific dates and by appointment type
#
# GET /v3/diary/{shortName}/appointmentsbetweendates
# operationId: DiaryController_GetAppointmentsBetweenDates
export def "diary-appointmentsbetweendates GetAppointmentsBetweenDates" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --branchID: string # The unique ID of the Branch
  --startDate: string # The search from date (format: date-time)
  --endDate: string # The search to date (format: date-time)
  --appointmentTypesToSearch: list # The appointment IDs to search for
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<AppointmentType: string, Cancelled: bool, Comment: string, CreatedAt: string, CreatedBy: string, ETag: string, End: string, LinkedProperties: list, NextRecurringDate: string, OID: string, Recurrence: int, RecurrenceType: string, RemindAt: string, RemindBefore: string, Staff: string, Start: string, Subject: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branchID" $branchID "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "appointmentTypesToSearch" $appointmentTypesToSearch "multi") (serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/diary/($shortName)/appointmentsbetweendates" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of all diary appointment types
#
# GET /v3/diary/{shortName}/appointmenttypes
# operationId: DiaryController_GetAppointmentTypes
export def "diary-appointmenttypes GetAppointmentTypes" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<ETag: string, Name: string, OID: string, SystemType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/diary/($shortName)/appointmenttypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All branches defined for a company
#
# GET /v3/diary/{shortName}/company/branches
# operationId: CompanyController_GetBranches
export def "diary-company-branches GetBranches" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/diary/($shortName)/company/branches" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific branch given its unique Object ID (OID)
#
# GET /v3/diary/{shortName}/company/branches/{branchID}
export def "diary-company-branches get" [
  shortName: string
  branchID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/diary/($shortName)/company/branches/($branchID)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves all recurring appointments:-
#
# GET /v3/diary/{shortName}/recurringappointment
# operationId: DiaryController_GetRecurringAppointments
export def "diary-recurringappointment GetRecurringAppointments" [
  shortName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --branchID: string # The unique ID of the Branch
  --appointmentTypesToSearch: list # The appointment IDs to search for
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<AppointmentType: string, Cancelled: bool, Comment: string, CreatedAt: string, CreatedBy: string, ETag: string, End: string, LinkedProperties: list, NextRecurringDate: string, OID: string, Recurrence: int, RecurrenceType: string, RemindAt: string, RemindBefore: string, Staff: string, Start: string, Subject: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branchID" $branchID "scalar") (serialize-qp "appointmentTypesToSearch" $appointmentTypesToSearch "multi") (serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/diary/($shortName)/recurringappointment" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Match Guest Parameters with existing applicants
#
# GET /v3/diary/{shortname}/{branchID}/guest/search
# operationId: DiaryController_SearchGuest
export def "diary-guest-search SearchGuest" [
  shortname: string
  branchID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let qp = [(serialize-qp "forename" $forename "scalar") (serialize-qp "emailaddress" $emailaddress "scalar") (serialize-qp "surname" $surname "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/diary/($shortname)/($branchID)/guest/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
