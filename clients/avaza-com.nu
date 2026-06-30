# Auto-generated client for Avaza API Documentation vv1
# Source: https://api.apis.guru/v2/specs/avaza.com/v1/swagger.json
# Auth: --token flag or $env.AVAZA_API_DOCUMENTATION_TOKEN

const BASE_URL = "https://api.avaza.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AVAZA_API_DOCUMENTATION_TOKEN | default "" }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body}.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk.
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://api.avaza.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "schedule-series-add-booking create" } } | get name | first)
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

# Create new Schedule Booking
#
# POST /ScheduleSeries/AddBooking
# operationId: ScheduleSeries_AddBooking
export def "schedule-series-add-booking create" [
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
  --category-idfk: int # format: int32
  --duration-type: string
  --end-date: string # format: date-time
  --hours-per-day: float # format: double
  --notes: string
  --project-idfk: int # format: int32
  --schedule-on-days-off: oneof<nothing, bool>
  --start-date: string # format: date-time
  --task-idfk: int # format: int32
  --total-duration: float # format: double
  --user-idfk: int # format: int32
]: any -> record<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ScheduleSeries/AddBooking" $auth.query)
  let req_body = {"CategoryIDFK": $category_idfk, "DurationType": $duration_type, "EndDate": $end_date, "HoursPerDay": $hours_per_day, "Notes": $notes, "ProjectIDFK": $project_idfk, "ScheduleOnDaysOff": $schedule_on_days_off, "StartDate": $start_date, "TaskIDFK": $task_idfk, "TotalDuration": $total_duration, "UserIDFK": $user_idfk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Create new Leave Booking
#
# POST /ScheduleSeries/AddLeave
# operationId: ScheduleSeries_AddLeave
export def "schedule-series-add-leave create" [
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
  --leave-end-date: string # format: date-time
  --leave-hours-per-day: float # format: double
  --leave-notes: string
  --leave-notify: oneof<nothing, bool>
  --leave-start-date: string # format: date-time
  --leave-type-idfk: int # format: int32
  --leave-user-idfk: int # format: int32
]: any -> record<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ScheduleSeries/AddLeave" $auth.query)
  let req_body = {"LeaveEndDate": $leave_end_date, "LeaveHoursPerDay": $leave_hours_per_day, "LeaveNotes": $leave_notes, "LeaveNotify": $leave_notify, "LeaveStartDate": $leave_start_date, "LeaveTypeIDFK": $leave_type_idfk, "LeaveUserIDFK": $leave_user_idfk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Edit Booking
#
# PUT /ScheduleSeries/EditBooking
# operationId: ScheduleSeries_EditBooking
export def "schedule-series-edit-booking update" [
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
  --category-idfk: int # format: int32
  --duration-type: string
  --end-date: string # format: date-time
  --hours-per-day: float # format: double
  --notes: string
  --project-idfk: int # format: int32
  --schedule-on-days-off: oneof<nothing, bool>
  --schedule-series-id: int # format: int64
  --start-date: string # format: date-time
  --task-idfk: int # format: int32
  --total-duration: float # format: double
  --user-idfk: int # format: int32
]: any -> record<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ScheduleSeries/EditBooking" $auth.query)
  let req_body = {"CategoryIDFK": $category_idfk, "DurationType": $duration_type, "EndDate": $end_date, "HoursPerDay": $hours_per_day, "Notes": $notes, "ProjectIDFK": $project_idfk, "ScheduleOnDaysOff": $schedule_on_days_off, "ScheduleSeriesID": $schedule_series_id, "StartDate": $start_date, "TaskIDFK": $task_idfk, "TotalDuration": $total_duration, "UserIDFK": $user_idfk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Edit Leave Booking
#
# PUT /ScheduleSeries/EditLeave
# operationId: ScheduleSeries_EditLeave
export def "schedule-series-edit-leave update" [
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
  --end-date: string # format: date-time
  --hours-per-day: float # format: double
  --leave-type-idfk: int # format: int32
  --notes: string
  --schedule-series-id: int # format: int64
  --start-date: string # format: date-time
  --user-idfk: int # format: int32
]: any -> record<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ScheduleSeries/EditLeave" $auth.query)
  let req_body = {"EndDate": $end_date, "HoursPerDay": $hours_per_day, "LeaveTypeIDFK": $leave_type_idfk, "Notes": $notes, "ScheduleSeriesID": $schedule_series_id, "StartDate": $start_date, "UserIDFK": $user_idfk} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Account Details
#
# GET /api/Account
# operationId: Account_Get
export def "account get" [
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
]: nothing -> record<AccountEmail: string, AccountID: int, AllowHidingCompletedTasksOnTimesheet: bool, BrandPrimaryColor: string, BrandPrimaryColorLuminance: string, CompanyName: string, CurrentServerTimeISO: string, DefaultCurrencyCode: string, ExpenseApprovalRequired: bool, LockApprovedExpenses: bool, LockApprovedTimesheets: bool, SC: string, Subdomain: string, TimesheetDayOfWeek: int, TimesheetDisplayFormatCode: string, WeeklyTimesheetReminder: bool, has24HourTimesheetFormat: bool, hasStartEndTimesheets: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Account" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets list of Bills
#
# GET /api/Bill
# operationId: Bill_Get
export def "bill list" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --qp-sort: string
  --company-idfk: int # format: int32
]: nothing -> record<Bills: table<AccountIDFK: int, Balance: float, BillNumber: string, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, DateVerified: string, DueDate: string, ExchangeRate: float, Issuer: record, LineItems: list, Links: record, Notes: string, Recipient: record, Subject: string, SupplierPONumber: string, TaxAmount: float, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string, TransactionTaxConfigCode: string>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $updated_after "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "Sort" $qp_sort "scalar") (serialize-qp "CompanyIDFK" $company_idfk "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Bill" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdatedAfter": $updated_after, "pageSize": $page_size, "pageNumber": $page_number, "Sort": $qp_sort, "CompanyIDFK": $company_idfk} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new draft Bill
#
# POST /api/Bill
# operationId: Bill_Post
# --LineItems item shape: {Description?: string, Discount?: float, InventoryItemIDFK?: int, InventoryItemName?: string, ProjectIDFK?: int, Quantity: float, TaxIDFK?: int, TaxName?: string, TaxPercent?: float, UnitPrice: float}
export def "bill create" [
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
  --bill-number: string # Pass any string. If left blank it will use the next number in the auto incrementing sequence. If an integer is passed then the largest integer will be use as the seed to auto generate the next invoice number in the sequence.
  --bill-template-idfk: int # If left blank the account default invoice template will be used. (format: int32)
  --company-idfk: int # If left blank then you must specify Company Name. (format: int32)
  --company-name: string # If left blank then you must specify Company ID. Specified Name will be used to match existing customer record. If not matched then it will be used to create a new customer. First Name, Last Name and Email will only be used if it is a new company. If the Company name appears multiple times we will check the email address to find a matching company. If email address doesn't identify a matching company then the invoice creation will be rejected.
  --currency-code: string # Expects ISO Standard 3 character currency code. If left blank the currency will default to account's currency in general setting. For existing companies this field will be ignored and the invoice will use the currency of the customer. For new customers if the currency is not specified then account currency will be used otherwise the specified currency will be used.
  --date-issued: string # If not specified it will use today's date. The date should be specified as local date. (format: date-time)
  --due-date: string # It will be auto calculated based on the payment term and issue date. Due Date must be greater than or equal to Issue Date. If the Due Date is specified then Payment Terms will be set to -1 (Custom) (format: date-time)
  --email: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --exchange-rate: float # Exchange rate is only valid for invoices in currency other than default account currency. If not specified it will get the market rate based on the Date Issued. (format: double)
  --firstname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --lastname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --line-items: list # item shape: {Description?: string, Discount?: float, InventoryItemIDFK?: int, InventoryItemName?: string, ProjectIDFK?: int, Quantity: float, TaxIDFK?: int, TaxName?: string, TaxPercent?: float, UnitPrice: float}
  --notes: string # Plain UTF8 text. (no HTML). Max 2000 characters
  --payment-terms: int # "If left blank we will set it to customer default. If specified then it must match one of your existing pre configured payment term periods. Your account starts with: (-1 --- Custom, 0 --- Upon Receipt, 7 --- 7 Days, 15 --- 15 Days, 30 --- 30 Days, 45 --- 45 Days, 60 --- 60 Days) (format: int32)
  --subject: string # Plain UTF8 text. (no HTML). 255 characters max
  --supplier-po-number: string # Plain UTF8 text. 100 characters max
  --transaction-prefix: string # A prefix for the Invoice number. e.g. 'INV'. If left blank it will be set to the account default. Max length 20 characters.
  --transaction-tax-config-code: string # Possible values are (EX --- Tax Exclusive, INC --- Tax Inclusive). If left empty it will use the account default.
]: any -> record<AccountIDFK: int, Balance: float, BillNumber: string, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, DateVerified: string, DueDate: string, ExchangeRate: float, Issuer: record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, CompanyIDFK: int, CompanyName: string>, LineItems: table<Amount: float, Description: string, Discount: float, InventoryItemIDFK: int, InventoryItemName: string, InventoryItemSKU: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaxAmount: float, TaxCode: string, TaxIDFK: int, TaxName: string, TransactionLineItemID: int, UnitPrice: float>, Links: record<Edit: string, View: string, WebView: string>, Notes: string, Recipient: record<RecipientBillingAddressCity: string, RecipientBillingAddressCountryCode: string, RecipientBillingAddressLine: string, RecipientBillingAddressPostCode: string, RecipientBillingAddressState: string, RecipientFormattedBillingAddress: string>, Subject: string, SupplierPONumber: string, TaxAmount: float, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string, TransactionTaxConfigCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Bill" $auth.query)
  let req_body = {"BillNumber": $bill_number, "BillTemplateIDFK": $bill_template_idfk, "CompanyIDFK": $company_idfk, "CompanyName": $company_name, "CurrencyCode": $currency_code, "DateIssued": $date_issued, "DueDate": $due_date, "Email": $email, "ExchangeRate": $exchange_rate, "Firstname": $firstname, "Lastname": $lastname, "LineItems": $line_items, "Notes": $notes, "PaymentTerms": $payment_terms, "Subject": $subject, "SupplierPONumber": $supplier_po_number, "TransactionPrefix": $transaction_prefix, "TransactionTaxConfigCode": $transaction_tax_config_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Gets a Bill by Bill ID
#
# GET /api/Bill/{id}
# operationId: Bill_GetByID
export def "bill get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Bill/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Gets list of Bill Payments
#
# GET /api/BillPayment
# operationId: BillPayment_Get
export def "bill-payment list" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
]: nothing -> record<PageNumber: int, PageSize: int, Payments: table<AccountIDFK: int, Balance: float, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: list, PaymentNumber: string, PaymentProviderCode: string, SupplierIDFK: int, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $updated_after "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/BillPayment" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdatedAfter": $updated_after, "pageSize": $page_size, "pageNumber": $page_number} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create new Bill Payment and optionally assign payment allocations to Bills
#
# POST /api/BillPayment
# operationId: BillPayment_Post
# --PaymentAllocations item shape: {AllocationAmount?: float, AllocationDate?: string, BillTransactionIDFK?: int}
export def "bill-payment create" [
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
  --amount: float # format: double
  --company-idfk: int # Only required if no invoice allocations specified. (format: int32)
  --currency-code: string # Optional for specifying the Bill Payment's Currency (3 letter ISO Currency Code).
  --date-issued: string # Date of Payment. If not specified, assumes today. (format: date-time)
  --exchange-rate: float # Optional. Only used when the Company's currency is different from the Avaza account's base currency. Specifies the exchange rate that should apply between the Company currency and base currency. If not provided we will obtain an up to date exchange rate for the Payment Issue Date. (format: double)
  --notes: string
  --payment-allocations: list # List of amounts within this payment that are allocated to invoices. The sum of these be less than or equal to the payment amount. — item shape: {AllocationAmount?: float, AllocationDate?: string, BillTransactionIDFK?: int}
  --payment-number: string # Optional. If not specified will be automatically generated
  --payment-provider-code: string # Optional for storing the payment provider who was the source of funds.
  --transaction-prefix: string # Optional to override the default prefix added to Payment Numbers
  --transaction-reference: string # Optional for storing the reference # of the payment method.
]: any -> record<AccountIDFK: int, Balance: float, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: table<AllocationAmount: float, AllocationDate: string, BillTransactionIDFK: int, PaymentTransactionIDFK: int, TransactionAllocationID: int>, PaymentNumber: string, PaymentProviderCode: string, SupplierIDFK: int, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/BillPayment" $auth.query)
  let req_body = {"Amount": $amount, "CompanyIDFK": $company_idfk, "CurrencyCode": $currency_code, "DateIssued": $date_issued, "ExchangeRate": $exchange_rate, "Notes": $notes, "PaymentAllocations": $payment_allocations, "PaymentNumber": $payment_number, "PaymentProviderCode": $payment_provider_code, "TransactionPrefix": $transaction_prefix, "TransactionReference": $transaction_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Gets a Bill Payment by Payment Transaction ID
#
# GET /api/BillPayment/{id}
# operationId: BillPayment_GetByID
export def "bill-payment get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<AccountIDFK: int, Balance: float, CurrencyCode: string, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: table<AllocationAmount: float, AllocationDate: string, BillTransactionIDFK: int, PaymentTransactionIDFK: int, TransactionAllocationID: int>, PaymentNumber: string, PaymentProviderCode: string, SupplierIDFK: int, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/BillPayment/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets list of Companies
#
# GET /api/Company
# operationId: Company_Get
export def "company list" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of results per page (format: int32)
  --page-number: int # 1 based page number to retrieve (format: int32)
  --qp-sort: string # (optional) Supply one of: "DateUpdated", "DateCreated", "CompanyName","DateUpdated desc","DateCreated desc", "CompanyName desc"
]: nothing -> record<Companies: table<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, Comments: string, CompanyID: int, CompanyName: string, Contacts: list, CurrencyCode: string, DateCreated: string, DateUpdated: string, DefaultTradingTermIDFK: int, Fax: string, Phone: string, TaxNumber: string, website: string>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $updated_after "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "Sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Company" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdatedAfter": $updated_after, "pageSize": $page_size, "pageNumber": $page_number, "Sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a Company
#
# POST /api/Company
# operationId: Company_Post
export def "company create" [
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
  --billing-address: string
  --billing-address-city: string
  --billing-address-line: string
  --billing-address-post-code: string
  --billing-address-state: string
  --billing-country-code: string
  --comments: string
  company_name: string
  --currency-code: string
  --fax: string
  --phone: string
  --tax-number: string
  --website: string
]: any -> record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, Comments: string, CompanyID: int, CompanyName: string, Contacts: table<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>, CurrencyCode: string, DateCreated: string, DateUpdated: string, DefaultTradingTermIDFK: int, Fax: string, Phone: string, TaxNumber: string, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Company" $auth.query)
  let req_body = {"BillingAddress": $billing_address, "BillingAddressCity": $billing_address_city, "BillingAddressLine": $billing_address_line, "BillingAddressPostCode": $billing_address_post_code, "BillingAddressState": $billing_address_state, "BillingCountryCode": $billing_country_code, "Comments": $comments, "CompanyName": $company_name, "CurrencyCode": $currency_code, "Fax": $fax, "Phone": $phone, "TaxNumber": $tax_number, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Update a Company record.
#
# PUT /api/Company
# operationId: Company_Put
export def "company update" [
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
  --billing-address: string
  --billing-address-city: string
  --billing-address-line: string
  --billing-address-post-code: string
  --billing-address-state: string
  --billing-country-code: string
  --comments: string
  --company-id: int # format: int32
  --company-name: string
  --fax: string
  --fields-to-update: list<string>
  --phone: string
  --tax-number: string
  --website: string
]: any -> record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, Comments: string, CompanyID: int, CompanyName: string, Contacts: table<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>, CurrencyCode: string, DateCreated: string, DateUpdated: string, DefaultTradingTermIDFK: int, Fax: string, Phone: string, TaxNumber: string, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Company" $auth.query)
  let req_body = {"BillingAddress": $billing_address, "BillingAddressCity": $billing_address_city, "BillingAddressLine": $billing_address_line, "BillingAddressPostCode": $billing_address_post_code, "BillingAddressState": $billing_address_state, "BillingCountryCode": $billing_country_code, "Comments": $comments, "CompanyID": $company_id, "CompanyName": $company_name, "Fax": $fax, "FieldsToUpdate": $fields_to_update, "Phone": $phone, "TaxNumber": $tax_number, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Gets minimal list of Companies.
#
# GET /api/Company/Lookup
# operationId: CompanyLookup
export def "company-lookup get" [
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
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --search: string # Search string to match against Company title
]: nothing -> record<Companies: table<CompanyID: int, CompanyName: string>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Company/Lookup" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pageSize": $page_size, "pageNumber": $page_number, "search": $search} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets Company by Company ID
#
# GET /api/Company/{id}
# operationId: Company_GetByID
export def "company get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, Comments: string, CompanyID: int, CompanyName: string, Contacts: table<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>, CurrencyCode: string, DateCreated: string, DateUpdated: string, DefaultTradingTermIDFK: int, Fax: string, Phone: string, TaxNumber: string, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Company/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets list of Contacts
#
# GET /api/Contact
# operationId: Contact_Get
export def "contact list" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --qp-sort: string
  --company-idfk: int # format: int32
]: nothing -> record<Contacts: table<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $updated_after "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "Sort" $qp_sort "scalar") (serialize-qp "CompanyIDFK" $company_idfk "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Contact" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdatedAfter": $updated_after, "pageSize": $page_size, "pageNumber": $page_number, "Sort": $qp_sort, "CompanyIDFK": $company_idfk} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a Contact
#
# POST /api/Contact
# operationId: Contact_Post
export def "contact create" [
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
  --company-billing-address: string
  --company-billing-address-city: string
  --company-billing-address-country-code: string
  --company-billing-address-line: string
  --company-billing-address-post-code: string
  --company-billing-address-state: string
  --company-idfk: int # format: int32
  --company-name: string
  contact_email: string
  --currency-code: string
  firstname: string
  lastname: string
  --mobile: string
  --phone: string
  --position-title: string
  --update-existing: oneof<nothing, bool>
]: any -> record<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Contact" $auth.query)
  let req_body = {"CompanyBillingAddress": $company_billing_address, "CompanyBillingAddressCity": $company_billing_address_city, "CompanyBillingAddressCountryCode": $company_billing_address_country_code, "CompanyBillingAddressLine": $company_billing_address_line, "CompanyBillingAddressPostCode": $company_billing_address_post_code, "CompanyBillingAddressState": $company_billing_address_state, "CompanyIDFK": $company_idfk, "CompanyName": $company_name, "ContactEmail": $contact_email, "CurrencyCode": $currency_code, "Firstname": $firstname, "Lastname": $lastname, "Mobile": $mobile, "Phone": $phone, "PositionTitle": $position_title, "UpdateExisting": $update_existing} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Gets Contact by Contact ID
#
# GET /api/Contact/{id}
# operationId: Contact_GetByID
export def "contact get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<CompanyIDFK: int, CompanyName: string, ContactID: int, DateCreated: string, DateUpdated: string, Email: string, Firstname: string, Lastname: string, Mobile: string, Phone: string, PositionTitle: string, TimeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Contact/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets list of CreditNotes
#
# GET /api/CreditNote
# operationId: CreditNote_Get
export def "credit-note list" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
]: nothing -> record<CreditNotes: table<Balance: float, CreditNoteAllocations: list, CreditNoteLineItems: list, CreditNoteNumber: string, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, Notes: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $updated_after "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/CreditNote" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdatedAfter": $updated_after, "pageSize": $page_size, "pageNumber": $page_number} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets Credit Note by CreditNoteID
#
# GET /api/CreditNote/{id}
# operationId: CreditNote_GetByID
export def "credit-note get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<Balance: float, CreditNoteAllocations: table<AllocationAmount: float, AllocationDate: string, CreditNoteTransactionIDFK: int, InvoiceTransactionIDFK: int, TransactionAllocationID: int>, CreditNoteLineItems: table<Amount: float, Description: string, Discount: float, Quantity: float, TaxAmount: float, TaxIDFK: int, TransactionLineItemID: int, UnitPrice: float>, CreditNoteNumber: string, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, Notes: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/CreditNote/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets list of Currencies
#
# GET /api/Currency
# operationId: Currency_Get
export def "currency get" [
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
]: nothing -> record<Currencies: table<CurrencyCode: string, DecimalPlaces: int, Name: string, Symbol: string, Symbol2: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Currency" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets list of Estimates
#
# GET /api/Estimate
# operationId: Estimate_Get
export def "estimate list" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --qp-sort: string
  --company-idfk: int # format: int32
]: nothing -> record<Estimates: table<AccountIDFK: int, Balance: float, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, DateCreated: string, DateIssued: string, DateSent: string, DateUpdated: string, DueDate: string, EstimateID: int, EstimateItemNumber: string, EstimatePrefix: string, EstimateStatusCode: string, EstimateTaxConfigCode: string, ExchangeRate: float, Issuer: record, LineItems: list, Links: record, Notes: string, Recipient: record, Subject: string, TaxAmount: float, TotalAmount: float>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $updated_after "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "Sort" $qp_sort "scalar") (serialize-qp "CompanyIDFK" $company_idfk "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Estimate" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdatedAfter": $updated_after, "pageSize": $page_size, "pageNumber": $page_number, "Sort": $qp_sort, "CompanyIDFK": $company_idfk} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new draft Estimate
#
# POST /api/Estimate
# operationId: Estimate_Post
# --LineItems item shape: {Description?: string, Discount?: float, InventoryItemIDFK?: int, InventoryItemName?: string, Quantity: float, TaxIDFK?: int, TaxName?: string, TaxPercent?: float, UnitPrice: float}
export def "estimate create" [
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
  --company-idfk: int # If left blank then you must specify Company Name. (format: int32)
  --company-name: string # If left blank then you must specify Company ID. Specified Name will be used to match existing customer record. If not matched then it will be used to create a new customer. First Name, Last Name and Email will only be used if it is a new company. If the Company name appears multiple times we will check the email address to find a matching company. If email address doesn't identify a matching company then the Estimate creation will be rejected.
  --currency-code: string # Expects ISO Standard 3 character currency code. If left blank the currency will default to account's currency in general setting. For existing companies this field will be ignored and the Estimate will use the currency of the customer. For new customers if the currency is not specified then account currency will be used otherwise the specified currency will be used.
  --customer-po-number: string # Plain UTF8 text. 100 characters max
  --date-issued: string # If not specified it will use today's date. The date should be specified as local date. (format: date-time)
  --due-date: string # It will be auto calculated based on the payment term and issue date. Due Date must be greater than or equal to Issue Date. If the Due Date is specified then Payment Terms will be set to -1 (Custom) (format: date-time)
  --email: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --estimate-number: string # Pass any string. If left blank it will use the next number in the auto incrementing sequence. If an integer is passed then the largest integer will be use as the seed to auto generate the next Estimate number in the sequence.
  --estimate-prefix: string # A prefix for the Estimate number. e.g. 'INV'. If left blank it will be set to the account default. Max length 20 characters.
  --estimate-tax-config-code: string # Possible values are (EX --- Tax Exclusive, INC --- Tax Inclusive). If left empty it will use the account default.
  --exchange-rate: float # Exchange rate is only valid for Estimates in currency other than default account currency. If not specified it will get the market rate based on the Date Issued. (format: double)
  --firstname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --invoice-template-idfk: int # If left blank the account default Estimate template will be used. (format: int32)
  --lastname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --line-items: list # item shape: {Description?: string, Discount?: float, InventoryItemIDFK?: int, InventoryItemName?: string, Quantity: float, TaxIDFK?: int, TaxName?: string, TaxPercent?: float, UnitPrice: float}
  --notes: string # Plain UTF8 text. (no HTML). Max 2000 characters
  --subject: string # Plain UTF8 text. (no HTML). 255 characters max
]: any -> record<AccountIDFK: int, Balance: float, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, DateCreated: string, DateIssued: string, DateSent: string, DateUpdated: string, DueDate: string, EstimateID: int, EstimateItemNumber: string, EstimatePrefix: string, EstimateStatusCode: string, EstimateTaxConfigCode: string, ExchangeRate: float, Issuer: record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, TaxNumber: string>, LineItems: table<Amount: float, Description: string, Discount: float, EstimateLineItemID: int, InventoryItemIDFK: int, InventoryItemName: string, InventoryItemSKU: string, Quantity: float, TaxAmount: float, TaxCode: string, TaxIDFK: int, TaxName: string, UnitPrice: float>, Links: record<ClientView: string, Edit: string, View: string>, Notes: string, Recipient: record<CompanyIDFK: int, CompanyName: string, RecipientBillingAddressCity: string, RecipientBillingAddressCountryCode: string, RecipientBillingAddressLine: string, RecipientBillingAddressPostCode: string, RecipientBillingAddressState: string, RecipientFormattedBillingAddress: string>, Subject: string, TaxAmount: float, TotalAmount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Estimate" $auth.query)
  let req_body = {"CompanyIDFK": $company_idfk, "CompanyName": $company_name, "CurrencyCode": $currency_code, "CustomerPONumber": $customer_po_number, "DateIssued": $date_issued, "DueDate": $due_date, "Email": $email, "EstimateNumber": $estimate_number, "EstimatePrefix": $estimate_prefix, "EstimateTaxConfigCode": $estimate_tax_config_code, "ExchangeRate": $exchange_rate, "Firstname": $firstname, "InvoiceTemplateIDFK": $invoice_template_idfk, "Lastname": $lastname, "LineItems": $line_items, "Notes": $notes, "Subject": $subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Gets Estimate by Estimate ID
#
# GET /api/Estimate/{id}
# operationId: Estimate_GetByID
export def "estimate get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Estimate/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Delete a Timesheet Entry
#
# DELETE /api/Expense
# operationId: Expense_Delete
export def "expense delete" [
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
  --body: list
]: any -> record<Results: table<ErrorMessage: string, ExpenseID: int, Success: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Expense" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets list of Expenses
#
# GET /api/Expense
# operationId: Expense_Get
export def "expense list" [
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
  --updated-after: string # format: date-time
  --expense-date-from: string # format: date-time
  --expense-date-to: string # format: date-time
  --user-email: string
  --user-id: int # format: int32
  --category-name: string
  --customer-id: int # format: int32
  --project-id: int # format: int32
  --is-chargeable: oneof<nothing, bool>
  --is-invoiced: oneof<nothing, bool>
  --expense-reimbursement-idfk: int # format: int64
  --expense-payment-method-idfk: int # format: int32
  --expense-approval-status-code: string
  --search: string
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --qp-sort: string
]: nothing -> record<Expenses: table<Amount: float, AttachmentPreviewURL: string, AttachmentURL: string, ChargeableStatusCode: string, CurrencyCode: string, CustomerIDFK: int, CustomerName: string, DateCreated: string, DateUpdated: string, Email: string, ExchangeRate: float, ExpenseApprovalStatusCode: string, ExpenseCategoryHasUnitPrice: bool, ExpenseCategoryIDFK: int, ExpenseCategoryName: string, ExpenseCategoryUnitName: string, ExpenseCategoryUnitPrice: float, ExpenseDate: string, ExpenseID: int, ExpensePaymentMethodIDFK: int, ExpensePaymentMethodName: string, ExpenseReimbursementIDFK: int, ExpenseReimbursementStatusCode: string, ExpenseReportIDFK: int, ExpenseReportName: string, FileAttachmentIDFK: int, Firstname: string, Lastname: string, Merchant: string, MerchantTaxNumber: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaskIDFK: int, TaskTitle: string, TaxAmount: float, TaxIDFK: int, TaxName: string, TransactionTaxConfigCode: string, TransactionTaxConfigName: string, UserIDFK: int, isChargeable: bool, isOfficialExchangeRate: bool, isReimbursable: bool>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $updated_after "scalar") (serialize-qp "ExpenseDateFrom" $expense_date_from "scalar") (serialize-qp "ExpenseDateTo" $expense_date_to "scalar") (serialize-qp "UserEmail" $user_email "scalar") (serialize-qp "UserID" $user_id "scalar") (serialize-qp "CategoryName" $category_name "scalar") (serialize-qp "CustomerID" $customer_id "scalar") (serialize-qp "ProjectID" $project_id "scalar") (serialize-qp "isChargeable" $is_chargeable "scalar") (serialize-qp "isInvoiced" $is_invoiced "scalar") (serialize-qp "ExpenseReimbursementIDFK" $expense_reimbursement_idfk "scalar") (serialize-qp "ExpensePaymentMethodIDFK" $expense_payment_method_idfk "scalar") (serialize-qp "ExpenseApprovalStatusCode" $expense_approval_status_code "scalar") (serialize-qp "Search" $search "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "Sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Expense" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdatedAfter": $updated_after, "ExpenseDateFrom": $expense_date_from, "ExpenseDateTo": $expense_date_to, "UserEmail": $user_email, "UserID": $user_id, "CategoryName": $category_name, "CustomerID": $customer_id, "ProjectID": $project_id, "isChargeable": $is_chargeable, "isInvoiced": $is_invoiced, "ExpenseReimbursementIDFK": $expense_reimbursement_idfk, "ExpensePaymentMethodIDFK": $expense_payment_method_idfk, "ExpenseApprovalStatusCode": $expense_approval_status_code, "Search": $search, "pageSize": $page_size, "pageNumber": $page_number, "Sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an Expense
#
# POST /api/Expense
# operationId: Expense_Post
export def "expense create" [
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
  --amount: float # Expense Amount (Required). Must be >= 0 (format: double)
  --currency-code: string # A 3-letter ISO CurrencyCode for the expense currency. (e.g. USD). If not provided, defaults to the Account base currency.
  --customer-idfk: int # The Avaza Customer ID to associate the Expense with. Either this field or CustomerName can be provided. (format: int32)
  --customer-name: string # The name of an existing customer in Avaza. Must be an exact (case insensitive) match.
  --exchange-rate: float # Optional (Only relevant if the expense currency is different to your account currency. If not provided we will look up the market exchange rate for you based on the expense date.) Exchange Rate = Expense Currency Amount / Base Currency Amount (e.g. if Expense currency is in AUD, and Base Currency is in USD, Exchange Rate = AUD $140 / USD $100 = 1.4) (format: double)
  --expense-category-idfk: int # The expense category to link the Expense to. If not provided, ExpenseCategoryName must be provided (format: int32)
  --expense-category-name: string # Must match an existing expense category name otherwise a new category will be created. If left blank Expense Category ID must be provided.
  --expense-date: string # The date of the expense entry (Required) (format: date-time)
  --expense-payment-method-idfk: int # (Optional) ID of Expense Payment Method. (format: int32)
  --file-attachment-i-ds: list<int> # Array of File Attachment IDs to associate with this expense. The files need to have already been uploaded. Currently only accepts a single file.
  --group-trip-name: string # Links the expense to a Grouping/Trip report. If no matching name found, creates a new Group/Trip Report name.
  --merchant: string # The name of the merchant.
  --merchant-tax-number: string # A Tax number identifier for the merchant.
  --notes: string # Expense Notes
  --project-idfk: int # The Avaza project ID to associate the Expense with. (format: int32)
  --project-name: string # Can work for matching an expense to a project, but only if it's an exact match for a single project under the customer.
  --quantity: float # Conditional - available for expenses that are assigned a unit priced based expense category. e.g Mileage (format: double)
  --task-idfk: int # (optional) TaskID of a Task to link the new Expense to. A Customer and Project must be provided also. (format: int32)
  --tax-idfk: int # Avaza Tax ID the expense belongs to. If left blank then Tax Name must be provided. (format: int32)
  --tax-name: string # Must exactly match an existing Tax Name that you have configured in Avaza Tax settings. If left blank then Tax ID must be provided.
  --transaction-tax-config-code: string # Optional - Enter "INC" if the tax amount is included in the expense amount otherwise enter "EX" when the amount exlcudes the tax. Defaults to "Ex". The tax amount on the expense will be autocalculated.
  --user-email: string # The email address of a Timesheet/Expense user in Avaza. If not provided, UserIDFK field must be provided.
  --user-idfk: int # UserID for a Timesheet/Expense user in Avaza. If not provided, UserEmail field must be provided (format: int32)
  --verify-and-save: oneof<nothing, bool> # Pass false if creating a draft expense. True otherwise.
  --is-chargeable: oneof<nothing, bool> # aka Billable. Defaults to false if not provided. If set to true, a CustomerIDFK or CustomerName must be provided.
  --is-reimbursable: oneof<nothing, bool> # Defaults to false if not provided.
]: any -> record<Amount: float, AttachmentPreviewURL: string, AttachmentURL: string, ChargeableStatusCode: string, CurrencyCode: string, CustomerIDFK: int, CustomerName: string, DateCreated: string, DateUpdated: string, Email: string, ExchangeRate: float, ExpenseApprovalStatusCode: string, ExpenseCategoryHasUnitPrice: bool, ExpenseCategoryIDFK: int, ExpenseCategoryName: string, ExpenseCategoryUnitName: string, ExpenseCategoryUnitPrice: float, ExpenseDate: string, ExpenseID: int, ExpensePaymentMethodIDFK: int, ExpensePaymentMethodName: string, ExpenseReimbursementIDFK: int, ExpenseReimbursementStatusCode: string, ExpenseReportIDFK: int, ExpenseReportName: string, FileAttachmentIDFK: int, Firstname: string, Lastname: string, Merchant: string, MerchantTaxNumber: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaskIDFK: int, TaskTitle: string, TaxAmount: float, TaxIDFK: int, TaxName: string, TransactionTaxConfigCode: string, TransactionTaxConfigName: string, UserIDFK: int, isChargeable: bool, isOfficialExchangeRate: bool, isReimbursable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Expense" $auth.query)
  let req_body = {"Amount": $amount, "CurrencyCode": $currency_code, "CustomerIDFK": $customer_idfk, "CustomerName": $customer_name, "ExchangeRate": $exchange_rate, "ExpenseCategoryIDFK": $expense_category_idfk, "ExpenseCategoryName": $expense_category_name, "ExpenseDate": $expense_date, "ExpensePaymentMethodIDFK": $expense_payment_method_idfk, "FileAttachmentIDs": $file_attachment_i_ds, "GroupTripName": $group_trip_name, "Merchant": $merchant, "MerchantTaxNumber": $merchant_tax_number, "Notes": $notes, "ProjectIDFK": $project_idfk, "ProjectName": $project_name, "Quantity": $quantity, "TaskIDFK": $task_idfk, "TaxIDFK": $tax_idfk, "TaxName": $tax_name, "TransactionTaxConfigCode": $transaction_tax_config_code, "UserEmail": $user_email, "UserIDFK": $user_idfk, "VerifyAndSave": $verify_and_save, "isChargeable": $is_chargeable, "isReimbursable": $is_reimbursable} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Update an Expense
#
# PUT /api/Expense
# operationId: Expense_Put
export def "expense update" [
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
  --amount: float # Expense Amount (Required). Must be >= 0 (format: double)
  --currency-code: string # A 3-letter ISO CurrencyCode for the expense currency. (e.g. USD). If not provided, defaults to the Account base currency.
  --customer-idfk: int # The Avaza Customer ID to associate the Expense with. (format: int32)
  --exchange-rate: float # Optional (Only relevant if the expense currency is different to your account currency. If not provided we will look up the market exchange rate for you based on the expense date.) Exchange Rate = Expense Currency Amount / Base Currency Amount (e.g. if Expense currency is in AUD, and Base Currency is in USD, Exchange Rate = AUD $140 / USD $100 = 1.4) (format: double)
  --expense-category-idfk: int # The expense category to link the Expense to. (format: int32)
  --expense-date: string # The date of the expense entry (format: date-time)
  expense_id: int # format: int64
  --expense-payment-method-idfk: int # (Optional) ID of Expense Payment Method. (format: int32)
  fields_to_update: list<string>
  --file-attachment-i-ds: list<int> # Array of File Attachment IDs to associate with this expense. The files need to have already been uploaded. Currently only accepts a single file.
  --group-trip-name: string # Links the expense to a Grouping/Trip report. If no matching name found, creates a new Group/Trip Report name.
  --merchant: string # The name of the merchant.
  --merchant-tax-number: string # A Tax number identifier for the merchant.
  --notes: string # Expense Notes
  --project-idfk: int # The Avaza project ID to associate the Expense with. (format: int32)
  --quantity: float # Conditional - available for expenses that are assigned a unit priced based expense category. e.g Mileage (format: double)
  --task-idfk: int # (optional) TaskID of a Task to link the new Expense to. A Customer and Project must be provided also. (format: int32)
  --tax-idfk: int # Avaza Tax ID the expense belongs to. (format: int32)
  --transaction-tax-config-code: string # Optional - Enter "INC" if the tax amount is included in the expense amount otherwise enter "EX" when the amount exlcudes the tax. Defaults to "Ex". The tax amount on the expense will be autocalculated.
  --verify-and-save: oneof<nothing, bool> # Pass false if creating a draft expense. True otherwise.
  --is-chargeable: oneof<nothing, bool> # aka Billable. Defaults to false if not provided. If set to true, a CustomerIDFK or CustomerName must be provided.
  --is-reimbursable: oneof<nothing, bool> # Defaults to false if not provided.
]: any -> record<Amount: float, AttachmentPreviewURL: string, AttachmentURL: string, ChargeableStatusCode: string, CurrencyCode: string, CustomerIDFK: int, CustomerName: string, DateCreated: string, DateUpdated: string, Email: string, ExchangeRate: float, ExpenseApprovalStatusCode: string, ExpenseCategoryHasUnitPrice: bool, ExpenseCategoryIDFK: int, ExpenseCategoryName: string, ExpenseCategoryUnitName: string, ExpenseCategoryUnitPrice: float, ExpenseDate: string, ExpenseID: int, ExpensePaymentMethodIDFK: int, ExpensePaymentMethodName: string, ExpenseReimbursementIDFK: int, ExpenseReimbursementStatusCode: string, ExpenseReportIDFK: int, ExpenseReportName: string, FileAttachmentIDFK: int, Firstname: string, Lastname: string, Merchant: string, MerchantTaxNumber: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaskIDFK: int, TaskTitle: string, TaxAmount: float, TaxIDFK: int, TaxName: string, TransactionTaxConfigCode: string, TransactionTaxConfigName: string, UserIDFK: int, isChargeable: bool, isOfficialExchangeRate: bool, isReimbursable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Expense" $auth.query)
  let req_body = {"Amount": $amount, "CurrencyCode": $currency_code, "CustomerIDFK": $customer_idfk, "ExchangeRate": $exchange_rate, "ExpenseCategoryIDFK": $expense_category_idfk, "ExpenseDate": $expense_date, "ExpenseID": $expense_id, "ExpensePaymentMethodIDFK": $expense_payment_method_idfk, "FieldsToUpdate": $fields_to_update, "FileAttachmentIDs": $file_attachment_i_ds, "GroupTripName": $group_trip_name, "Merchant": $merchant, "MerchantTaxNumber": $merchant_tax_number, "Notes": $notes, "ProjectIDFK": $project_idfk, "Quantity": $quantity, "TaskIDFK": $task_idfk, "TaxIDFK": $tax_idfk, "TransactionTaxConfigCode": $transaction_tax_config_code, "VerifyAndSave": $verify_and_save, "isChargeable": $is_chargeable, "isReimbursable": $is_reimbursable} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# POST /api/Expense/Attachment
#
# operationId: ExpenseAttachment
export def "expense-attachment create" [
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
  file: path # Upload software package
]: any -> record<FileAttachments: table<FileAttachmentID: int, OriginalFilename: string, PreviewBaseURL: string, PublicFileURL: string, SizeBytes: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Expense/Attachment" $auth.query)
  let req_body = {"File": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["File"] $dry_run)
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Gets an Expense Entry by Expense ID
#
# GET /api/Expense/{id}
# operationId: Expense_GetByID
export def "expense get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<Amount: float, AttachmentPreviewURL: string, AttachmentURL: string, ChargeableStatusCode: string, CurrencyCode: string, CustomerIDFK: int, CustomerName: string, DateCreated: string, DateUpdated: string, Email: string, ExchangeRate: float, ExpenseApprovalStatusCode: string, ExpenseCategoryHasUnitPrice: bool, ExpenseCategoryIDFK: int, ExpenseCategoryName: string, ExpenseCategoryUnitName: string, ExpenseCategoryUnitPrice: float, ExpenseDate: string, ExpenseID: int, ExpensePaymentMethodIDFK: int, ExpensePaymentMethodName: string, ExpenseReimbursementIDFK: int, ExpenseReimbursementStatusCode: string, ExpenseReportIDFK: int, ExpenseReportName: string, FileAttachmentIDFK: int, Firstname: string, Lastname: string, Merchant: string, MerchantTaxNumber: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaskIDFK: int, TaskTitle: string, TaxAmount: float, TaxIDFK: int, TaxName: string, TransactionTaxConfigCode: string, TransactionTaxConfigName: string, UserIDFK: int, isChargeable: bool, isOfficialExchangeRate: bool, isReimbursable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Expense/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Submit Expenses for Approval.
#
# POST /api/ExpenseApproval/Submit
# operationId: ExpenseApproval
export def "expense-approval-submit create" [
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
  --user-id: int # The user to submit the Expenses for. Defaults to current user. Only allowed to be different from the current user when the current user has rights to Impersonate other users. (format: int32)
  --send-notifications: oneof<nothing, bool> # Send email alerts to expense approvers. Defaults to true
  --body: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UserID" $user_id "scalar") (serialize-qp "SendNotifications" $send_notifications "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ExpenseApproval/Submit" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"UserID": $user_id, "SendNotifications": $send_notifications} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets list of Expense Categories
#
# GET /api/ExpenseCategory
# operationId: ExpenseCategory_Get
export def "expense-category get" [
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
  --is-enabled: oneof<nothing, bool> # Optional filter on for enabled/disabled categories. Defaults to true.
]: nothing -> record<Categories: table<Enabled: bool, ExpenseCategoryID: int, Name: string, UnitName: string, UnitPrice: float, hasUnitPrice: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isEnabled" $is_enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ExpenseCategory" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"isEnabled": $is_enabled} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets minimal list of Expense Groups.
#
# GET /api/ExpenseGroup/Lookup
# operationId: ExpenseGroupLookup
export def "expense-group-lookup get" [
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
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --search: string # Search string to match against Expense Group Name
]: nothing -> record<ExpenseGroups: table<ExpenseGroupID: int, Name: string>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ExpenseGroup/Lookup" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pageSize": $page_size, "pageNumber": $page_number, "search": $search} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets minimal list of Expense Merchants.
#
# GET /api/ExpenseMerchant/Lookup
# operationId: ExpenseMerchangeLookup
export def "expense-merchant-lookup get-merchange" [
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
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --search: string # Search string to match against Expense Group Name
]: nothing -> record<ExpenseMerchants: table<MerchantName: string>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ExpenseMerchant/Lookup" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pageSize": $page_size, "pageNumber": $page_number, "search": $search} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets minimal list of Expense Payment Methods.
#
# GET /api/ExpensePaymentMethod/Lookup
# operationId: ExpensePaymentMethodLookup
export def "expense-payment-method-lookup get" [
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
]: nothing -> record<ExpensePaymentMethods: table<ExpensePaymentMethodID: int, Name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/ExpensePaymentMethod/Lookup" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets Basic Summary of Expense Statistics
#
# GET /api/ExpenseSummary
# operationId: ExpenseSummary_Get
export def "expense-summary get" [
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
  --model-group-by: list<string> # (Optional) Combine one, two or three levels of Grouping. Combine these possible grouping values: "Category", "ChargeableStatus", "Merchant", "ApprovalStatus", "ReimbursementStatus", "Customer", "Project", "User", "Task", "Year", "Month", "Day", "Week".
  --model-expense-date-from: string # (Required) Filter for expenses with expense dates greater or equal to the specified date. e.g. 2019-01-25. (format: date-time)
  --model-expense-date-to: string # (Required) Filter for expenses with an expense date smaller or equal to the specified date. e.g. 2019-01-25. (format: date-time)
  --model-user-id: list<int> # (Optional) Defaults to the current user. Provide one or more UserIDs of Users whose expenses should be retrieved. If the current user doesn't have impersonation rights, then they will only see their own data.
  --model-project-id: int # (Optional) Filter by Project (format: int32)
]: nothing -> record<ExpenseDateFrom: string, ExpenseDateTo: string, GroupData: table<GroupData: list, GroupID: string, GroupName: string, TotalAmount: float>, GroupingLevels: list<string>, TotalAmount: float, UserID: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model.groupBy" $model_group_by "multi") (serialize-qp "model.expenseDateFrom" $model_expense_date_from "scalar") (serialize-qp "model.expenseDateTo" $model_expense_date_to "scalar") (serialize-qp "model.userID" $model_user_id "multi") (serialize-qp "model.projectID" $model_project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ExpenseSummary" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"model.groupBy": $model_group_by, "model.expenseDateFrom": $model_expense_date_from, "model.expenseDateTo": $model_expense_date_to, "model.userID": $model_user_id, "model.projectID": $model_project_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets list of Fixed Amounts
#
# GET /api/FixedAmount
# operationId: FixedAmount_Get
export def "fixed-amount get" [
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
  --updated-after: string # format: date-time
  --entry-date-from: string # format: date-time
  --entry-date-to: string # format: date-time
  --project-id: int # (Optional) The ProjectID of a Project to filter Fixed Amounts for (format: int32)
  --task-id: int # (Optional) The TaskID of a Task to filter Fixed Amounts for (format: int32)
  --is-invoiced: oneof<nothing, bool>
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --qp-sort: string # Optional sorting instruction. Currently possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc","EntryDate", "EntryDate desc", "StartTimeLocal","StartTimeLocal desc", "TimeSheetEntryID", "TimeSheetEntryID desc"
]: nothing -> record<FixedAmounts: table<Amount: float, DateCreated: string, DateUpdated: string, FixedAmountID: int, InventoryItemIDFK: int, InventoryItemName: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, TaskIDFK: int, TaskTitle: string, UpdatedByUserIDFK: int, isInvoiced: bool>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $updated_after "scalar") (serialize-qp "EntryDateFrom" $entry_date_from "scalar") (serialize-qp "EntryDateTo" $entry_date_to "scalar") (serialize-qp "ProjectID" $project_id "scalar") (serialize-qp "TaskID" $task_id "scalar") (serialize-qp "isInvoiced" $is_invoiced "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "Sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/FixedAmount" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdatedAfter": $updated_after, "EntryDateFrom": $entry_date_from, "EntryDateTo": $entry_date_to, "ProjectID": $project_id, "TaskID": $task_id, "isInvoiced": $is_invoiced, "pageSize": $page_size, "pageNumber": $page_number, "Sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets list of Inventory
#
# GET /api/Inventory
# operationId: Inventory_Get
export def "inventory list" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
]: nothing -> record<Inventory: table<CostPrice: float, DateCreated: string, DateUpdated: string, Description: string, InventoryItemID: int, Name: string, SKU: string, SalePrice: float, SaleTaxIDFK: int, isHidden: bool>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $updated_after "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Inventory" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdatedAfter": $updated_after, "pageSize": $page_size, "pageNumber": $page_number} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets InventoryItem by InventoryItem ID
#
# GET /api/Inventory/{id}
# operationId: Inventory_GetByID
export def "inventory get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Inventory/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Gets list of Invoices
#
# GET /api/Invoice
# operationId: Invoice_Get
export def "invoice list" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --qp-sort: string
  --company-idfk: int # format: int32
]: nothing -> record<Invoices: table<AccountIDFK: int, Balance: float, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, CustomerPONumber: string, DateCreated: string, DateIssued: string, DateSent: string, DateUpdated: string, DueDate: string, ExchangeRate: float, InvoiceNumber: string, Issuer: record, LineItems: list, Links: record, Notes: string, Recipient: record, Subject: string, TaxAmount: float, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string, TransactionTaxConfigCode: string>, PageNumber: int, PageSize: int, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $updated_after "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "Sort" $qp_sort "scalar") (serialize-qp "CompanyIDFK" $company_idfk "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Invoice" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdatedAfter": $updated_after, "pageSize": $page_size, "pageNumber": $page_number, "Sort": $qp_sort, "CompanyIDFK": $company_idfk} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new draft invoice
#
# POST /api/Invoice
# operationId: Invoice_Post
# --LineItems item shape: {Description?: string, Discount?: float, InventoryItemIDFK?: int, InventoryItemName?: string, ProjectIDFK?: int, Quantity: float, TaxIDFK?: int, TaxName?: string, TaxPercent?: float, UnitPrice: float}
export def "invoice create" [
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
  --company-idfk: int # If left blank then you must specify Company Name. (format: int32)
  --company-name: string # If left blank then you must specify Company ID. Specified Name will be used to match existing customer record. If not matched then it will be used to create a new customer. First Name, Last Name and Email will only be used if it is a new company. If the Company name appears multiple times we will check the email address to find a matching company. If email address doesn't identify a matching company then the invoice creation will be rejected.
  --currency-code: string # Expects ISO Standard 3 character currency code. If left blank the currency will default to account's currency in general setting. For existing companies this field will be ignored and the invoice will use the currency of the customer. For new customers if the currency is not specified then account currency will be used otherwise the specified currency will be used.
  --customer-po-number: string # Plain UTF8 text. 100 characters max
  --date-issued: string # If not specified it will use today's date. The date should be specified as local date. (format: date-time)
  --due-date: string # It will be auto calculated based on the payment term and issue date. Due Date must be greater than or equal to Issue Date. If the Due Date is specified then Payment Terms will be set to -1 (Custom) (format: date-time)
  --email: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --exchange-rate: float # Exchange rate is only valid for invoices in currency other than default account currency. If not specified it will get the market rate based on the Date Issued. (format: double)
  --firstname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --invoice-number: string # Pass any string. If left blank it will use the next number in the auto incrementing sequence. If an integer is passed then the largest integer will be use as the seed to auto generate the next invoice number in the sequence.
  --invoice-template-idfk: int # If left blank the account default invoice template will be used. (format: int32)
  --lastname: string # Specified value will be used to create a new customer contact only if a new customer is being created.
  --line-items: list # item shape: {Description?: string, Discount?: float, InventoryItemIDFK?: int, InventoryItemName?: string, ProjectIDFK?: int, Quantity: float, TaxIDFK?: int, TaxName?: string, TaxPercent?: float, UnitPrice: float}
  --notes: string # Plain UTF8 text. (no HTML). Max 2000 characters
  --payment-terms: int # "If left blank we will set it to customer default. If specified then it must match one of your existing pre configured payment term periods. Your account starts with: (-1 --- Custom, 0 --- Upon Receipt, 7 --- 7 Days, 15 --- 15 Days, 30 --- 30 Days, 45 --- 45 Days, 60 --- 60 Days) (format: int32)
  --subject: string # Plain UTF8 text. (no HTML). 255 characters max
  --transaction-prefix: string # A prefix for the Invoice number. e.g. 'INV'. If left blank it will be set to the account default. Max length 20 characters.
  --transaction-tax-config-code: string # Possible values are (EX --- Tax Exclusive, INC --- Tax Inclusive). If left empty it will use the account default.
]: any -> record<AccountIDFK: int, Balance: float, CompanyIDFK: int, CompanyName: string, CurrencyCode: string, CustomerPONumber: string, DateCreated: string, DateIssued: string, DateSent: string, DateUpdated: string, DueDate: string, ExchangeRate: float, InvoiceNumber: string, Issuer: record<BillingAddress: string, BillingAddressCity: string, BillingAddressLine: string, BillingAddressPostCode: string, BillingAddressState: string, BillingCountryCode: string, TaxNumber: string>, LineItems: table<Amount: float, Description: string, Discount: float, InventoryItemIDFK: int, InventoryItemName: string, InventoryItemSKU: string, ProjectIDFK: int, ProjectTitle: string, Quantity: float, TaxAmount: float, TaxCode: string, TaxIDFK: int, TaxName: string, TransactionLineItemID: int, UnitPrice: float>, Links: record<ClientView: string, Edit: string, View: string>, Notes: string, Recipient: record<CompanyIDFK: int, CompanyName: string, RecipientBillingAddressCity: string, RecipientBillingAddressCountryCode: string, RecipientBillingAddressLine: string, RecipientBillingAddressPostCode: string, RecipientBillingAddressState: string, RecipientFormattedBillingAddress: string>, Subject: string, TaxAmount: float, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionStatusCode: string, TransactionTaxConfigCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Invoice" $auth.query)
  let req_body = {"CompanyIDFK": $company_idfk, "CompanyName": $company_name, "CurrencyCode": $currency_code, "CustomerPONumber": $customer_po_number, "DateIssued": $date_issued, "DueDate": $due_date, "Email": $email, "ExchangeRate": $exchange_rate, "Firstname": $firstname, "InvoiceNumber": $invoice_number, "InvoiceTemplateIDFK": $invoice_template_idfk, "Lastname": $lastname, "LineItems": $line_items, "Notes": $notes, "PaymentTerms": $payment_terms, "Subject": $subject, "TransactionPrefix": $transaction_prefix, "TransactionTaxConfigCode": $transaction_tax_config_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Gets Invoice by Invoice ID
#
# GET /api/Invoice/{id}
# operationId: Invoice_GetByID
export def "invoice get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Invoice/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Gets list of Payments
#
# GET /api/Payment
# operationId: Payment_Get
export def "payment list" [
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
  --updated-after: string # format: date-time
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
]: nothing -> record<PageNumber: int, PageSize: int, Payments: table<AccountIDFK: int, Balance: float, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: list, PaymentNumber: string, PaymentProviderCode: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $updated_after "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Payment" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdatedAfter": $updated_after, "pageSize": $page_size, "pageNumber": $page_number} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create new Payment and optionally assign payment allocations to Invoices
#
# POST /api/Payment
# operationId: Payment_Post
# --PaymentAllocations item shape: {AllocationAmount?: float, AllocationDate?: string, InvoiceTransactionIDFK?: int}
export def "payment create" [
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
  --amount: float # format: double
  --customer-idfk: int # Only required if no invoice allocations specified. (format: int32)
  --date-issued: string # Date of Payment. If not specified, assumes today. (format: date-time)
  --exchange-rate: float # Optional. Only used when the Customer's currecy is different from the Avaza account's base currency. Specifies the exchange rate that should apply between the customer currency and base currency. If not provided we will obtain an up to date exchange rate for the Payment Issue Date. (format: double)
  --notes: string
  --payment-allocations: list # List of amounts within this payment that are allocated to invoices. The sum of these be less than or equal to the payment amount. — item shape: {AllocationAmount?: float, AllocationDate?: string, InvoiceTransactionIDFK?: int}
  --payment-number: string # Optional. If not specified will be automatically generated
  --payment-provider-code: string # Optional for storing the payment provider who was the source of funds.
  --transaction-prefix: string # Optional to override the default prefix added to Payment Numbers
  --transaction-reference: string # Optional for storing the reference # of the payment method.
]: any -> record<AccountIDFK: int, Balance: float, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: table<AllocationAmount: float, AllocationDate: string, InvoiceTransactionIDFK: int, PaymentTransactionIDFK: int, TransactionAllocationID: int>, PaymentNumber: string, PaymentProviderCode: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Payment" $auth.query)
  let req_body = {"Amount": $amount, "CustomerIDFK": $customer_idfk, "DateIssued": $date_issued, "ExchangeRate": $exchange_rate, "Notes": $notes, "PaymentAllocations": $payment_allocations, "PaymentNumber": $payment_number, "PaymentProviderCode": $payment_provider_code, "TransactionPrefix": $transaction_prefix, "TransactionReference": $transaction_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Gets Payment by Payment Transaction ID
#
# GET /api/Payment/{id}
# operationId: Payment_GetByID
export def "payment get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<AccountIDFK: int, Balance: float, CurrencyCode: string, CustomerIDFK: int, DateCreated: string, DateIssued: string, DateUpdated: string, ExchangeRate: float, Notes: string, PaymentAllocations: table<AllocationAmount: float, AllocationDate: string, InvoiceTransactionIDFK: int, PaymentTransactionIDFK: int, TransactionAllocationID: int>, PaymentNumber: string, PaymentProviderCode: string, TotalAmount: float, TransactionID: int, TransactionPrefix: string, TransactionReference: string, TransactionStatusCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Payment/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets list of Projects
#
# GET /api/Project
# operationId: Project_Get
export def "project list" [
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
  --updated-after: string # Only show project records updated after a certain date (UTC) (format: date-time)
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --qp-sort: string # A column to sort on. Current possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc"
  --timesheet-user-id: int # Filter to the projects that the supplied UserID can add timesheets to (format: int32)
  --include-archived: oneof<nothing, bool> # Include Archived Projects in the results
]: nothing -> record<PageNumber: int, PageSize: int, Projects: table<CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, DefaultAccountTaskTypeIDFK: int, DefaultAccountTaskTypeName: string, Notes: string, ProjectCategoryIDFK: int, ProjectCategoryName: string, ProjectCode: string, ProjectID: int, ProjectOwnerUserIDFK: int, Title: string, isArchived: bool, isTaskRequiredOnTimesheet: bool>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $updated_after "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "Sort" $qp_sort "scalar") (serialize-qp "TimesheetUserID" $timesheet_user_id "scalar") (serialize-qp "includeArchived" $include_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Project" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdatedAfter": $updated_after, "pageSize": $page_size, "pageNumber": $page_number, "Sort": $qp_sort, "TimesheetUserID": $timesheet_user_id, "includeArchived": $include_archived} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a Project
#
# POST /api/Project
# operationId: Project_Post
export def "project create" [
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
  --budget-amount: float # format: double
  --budget-hours: float # format: double
  --company-idfk: int # An ID of a company in Avaza to create the Project under. You must provide either a CompanyID, or a CompanyName (format: int32)
  --company-name: string # The name for a Company to create the project under. Will create company unless it matches an existing company name
  --currency-code: string # The ISO 3 letter currency code to use when creating a new Company. If not provided, the account's default currency will be used.
  --end-date: string # format: date-time
  --populate-default-project-members: oneof<nothing, bool> # Defaults to true.
  --project-category-idfk: int # format: int32
  --project-code: string # Used when Manual Project Codes are enabled
  --project-notes: string # Any descriptive notes about the project. (2000 characters max)
  --project-status-code: string
  project_title: string # The title of the new project. (255 characters max)
  --start-date: string # format: date-time
  --timesheet-approval-requiredby-default: oneof<nothing, bool>
  --is-task-required-on-timesheet: oneof<nothing, bool>
]: any -> record<BudgetAmount: float, BudgetHours: float, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, DefaultAccountTaskTypeIDFK: int, DefaultAccountTaskTypeName: string, EndDate: string, Members: table<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>, Notes: string, ProjectBillableTypeCode: string, ProjectBudgetTypeCode: string, ProjectCategoryColor: string, ProjectCategoryIDFK: int, ProjectCategoryName: string, ProjectCode: string, ProjectHourlyRate: float, ProjectID: int, ProjectOwnerUserIDFK: int, ProjectStatusCode: string, ProjectTags: table<Name: string, ProjectTagID: int>, Sections: table<DisplayOrder: int, EndDate: string, SectionID: int, StartDate: string, Title: string>, StartDate: string, Title: string, isArchived: bool, isTaskRequiredOnTimesheet: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Project" $auth.query)
  let req_body = {"BudgetAmount": $budget_amount, "BudgetHours": $budget_hours, "CompanyIDFK": $company_idfk, "CompanyName": $company_name, "CurrencyCode": $currency_code, "EndDate": $end_date, "PopulateDefaultProjectMembers": $populate_default_project_members, "ProjectCategoryIDFK": $project_category_idfk, "ProjectCode": $project_code, "ProjectNotes": $project_notes, "ProjectStatusCode": $project_status_code, "ProjectTitle": $project_title, "StartDate": $start_date, "TimesheetApprovalRequiredbyDefault": $timesheet_approval_requiredby_default, "isTaskRequiredOnTimesheet": $is_task_required_on_timesheet} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Update an Project
#
# PUT /api/Project
# operationId: Project_Put
export def "project update" [
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
  --budget-amount: float # format: double
  --budget-hours: float # format: double
  --end-date: string # format: date-time
  --fields-to-update: list<string>
  --project-billable-type-code: string # The billing method of the project. (string, optional) Possible values: CategoryHourly, NoRate, NotBillable, PersonHourly, ProjectHourly
  --project-budget-type-code: string # The project budgeting type. (string, optional) Possible values: NoBudget, PersonHours, ProjectFees, ProjectHours, CategoryHours
  --project-category-idfk: int # format: int32
  --project-id: int # The ID of the Project to update (format: int32)
  --project-notes: string # (optional) Any descriptive notes about the project. (2000 characters max)
  --project-status-code: string # Update the project status (string, optional): (Possible values: NotStarted, InProgress, Complete, OnHold)
  --project-title: string # (optional) An updated project title. (255 characters max)
  --start-date: string # format: date-time
  --timesheet-approval-requiredby-default: oneof<nothing, bool> # Whether timesheet approval should be required by default for newly added project members.
  --is-task-required-on-timesheet: oneof<nothing, bool> # Whether timesheets entered against this project require a task to be selected.
]: any -> record<BudgetAmount: float, BudgetHours: float, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, DefaultAccountTaskTypeIDFK: int, DefaultAccountTaskTypeName: string, EndDate: string, Members: table<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>, Notes: string, ProjectBillableTypeCode: string, ProjectBudgetTypeCode: string, ProjectCategoryColor: string, ProjectCategoryIDFK: int, ProjectCategoryName: string, ProjectCode: string, ProjectHourlyRate: float, ProjectID: int, ProjectOwnerUserIDFK: int, ProjectStatusCode: string, ProjectTags: table<Name: string, ProjectTagID: int>, Sections: table<DisplayOrder: int, EndDate: string, SectionID: int, StartDate: string, Title: string>, StartDate: string, Title: string, isArchived: bool, isTaskRequiredOnTimesheet: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Project" $auth.query)
  let req_body = {"BudgetAmount": $budget_amount, "BudgetHours": $budget_hours, "EndDate": $end_date, "FieldsToUpdate": $fields_to_update, "ProjectBillableTypeCode": $project_billable_type_code, "ProjectBudgetTypeCode": $project_budget_type_code, "ProjectCategoryIDFK": $project_category_idfk, "ProjectID": $project_id, "ProjectNotes": $project_notes, "ProjectStatusCode": $project_status_code, "ProjectTitle": $project_title, "StartDate": $start_date, "TimesheetApprovalRequiredbyDefault": $timesheet_approval_requiredby_default, "isTaskRequiredOnTimesheet": $is_task_required_on_timesheet} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Gets minimal list of active Projects for the current user
#
# GET /api/Project/Lookup
# operationId: ProjectLookup
export def "project-lookup get" [
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
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --timesheet-user-id: int # Optionally Filter to the projects that the supplied UserID can add timesheets to (format: int32)
  --company-idfk: int # Optionally Filter for a specific Company ID (format: int32)
  --search: string # Search string to match against Project title and Customer name
]: nothing -> record<PageSize: int, companies: table<CompanyID: int, CompanyName: string, projects: list>, hasMore: bool, pageNumber: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "TimesheetUserID" $timesheet_user_id "scalar") (serialize-qp "CompanyIDFK" $company_idfk "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Project/Lookup" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pageSize": $page_size, "pageNumber": $page_number, "TimesheetUserID": $timesheet_user_id, "CompanyIDFK": $company_idfk, "search": $search} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets Project by Project ID
#
# GET /api/Project/{id}
# operationId: Project_GetByID
export def "project get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<BudgetAmount: float, BudgetHours: float, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, DefaultAccountTaskTypeIDFK: int, DefaultAccountTaskTypeName: string, EndDate: string, Members: table<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>, Notes: string, ProjectBillableTypeCode: string, ProjectBudgetTypeCode: string, ProjectCategoryColor: string, ProjectCategoryIDFK: int, ProjectCategoryName: string, ProjectCode: string, ProjectHourlyRate: float, ProjectID: int, ProjectOwnerUserIDFK: int, ProjectStatusCode: string, ProjectTags: table<Name: string, ProjectTagID: int>, Sections: table<DisplayOrder: int, EndDate: string, SectionID: int, StartDate: string, Title: string>, StartDate: string, Title: string, isArchived: bool, isTaskRequiredOnTimesheet: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Project/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets list of Project Members
#
# GET /api/ProjectMember
# operationId: ProjectMember_Get
export def "project-member get" [
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
  --project-id: int # Get Project members filtered by ProjectID (format: int32)
  --user-id: int # Get Project members filtered by UserID (format: int32)
]: nothing -> record<ProjectMembers: table<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ProjectID" $project_id "scalar") (serialize-qp "UserID" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ProjectMember" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ProjectID": $project_id, "UserID": $user_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Assign a user as a Member of a Project
#
# POST /api/ProjectMember
# operationId: ProjectMember_Post
export def "project-member create" [
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
  --budget-amount: float # Optional (format: double)
  --cost-amount: float # Optional. If not provided, defaults to the User's default Cost Amount. (format: double)
  --project-idfk: int # Required. The ProjectID (format: int32)
  --rate-amount: float # Optional. If not provided, defaults to the User's default Rate Amount. (format: double)
  --user-idfk: int # Required. The UserID to assign (format: int32)
  --can-comment-on-tasks: oneof<nothing, bool>
  --can-create-tasks: oneof<nothing, bool>
  --can-delete-tasks: oneof<nothing, bool>
  --can-update-tasks: oneof<nothing, bool>
  --is-project-manager: oneof<nothing, bool>
  --is-timesheet-allowed: oneof<nothing, bool>
  --is-timesheet-approval-required: oneof<nothing, bool>
  --is-timesheet-approver: oneof<nothing, bool>
]: any -> record<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/ProjectMember" $auth.query)
  let req_body = {"BudgetAmount": $budget_amount, "CostAmount": $cost_amount, "ProjectIDFK": $project_idfk, "RateAmount": $rate_amount, "UserIDFK": $user_idfk, "canCommentOnTasks": $can_comment_on_tasks, "canCreateTasks": $can_create_tasks, "canDeleteTasks": $can_delete_tasks, "canUpdateTasks": $can_update_tasks, "isProjectManager": $is_project_manager, "isTimesheetAllowed": $is_timesheet_allowed, "isTimesheetApprovalRequired": $is_timesheet_approval_required, "isTimesheetApprover": $is_timesheet_approver} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Update a Member of a Project
#
# PUT /api/ProjectMember
# operationId: ProjectMember_Put
export def "project-member update" [
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
  --budget-amount: float # A new Budget Amount. Defaults to null. (format: double)
  --cost-amount: float # A new Cost Amount. Defaults to null. (format: double)
  fields_to_update: list<string> # A string array of field names to be updated.
  project_idfk: int # Required. The ProjectID (format: int32)
  --rate-amount: float # A new Rate Amount. Defaults to null. (format: double)
  user_idfk: int # Required. The UserID (format: int32)
  --can-comment-on-tasks: oneof<nothing, bool>
  --can-create-tasks: oneof<nothing, bool>
  --can-delete-tasks: oneof<nothing, bool>
  --can-update-tasks: oneof<nothing, bool>
  --is-project-manager: oneof<nothing, bool>
  --is-timesheet-allowed: oneof<nothing, bool>
  --is-timesheet-approval-required: oneof<nothing, bool>
  --is-timesheet-approver: oneof<nothing, bool>
]: any -> record<BudgetAmount: float, CostAmount: float, Email: string, Firstname: string, Fullname: string, Lastname: string, ProjectIDFK: int, RateAmount: float, UserIDFK: int, canCommentOnTasks: bool, canCreateTasks: bool, canDeleteTasks: bool, canUpdateTasks: bool, isMemberDisabled: bool, isProjectManager: bool, isTimesheetAllowed: bool, isTimesheetApprovalRequired: bool, isTimesheetApprover: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/ProjectMember" $auth.query)
  let req_body = {"BudgetAmount": $budget_amount, "CostAmount": $cost_amount, "FieldsToUpdate": $fields_to_update, "ProjectIDFK": $project_idfk, "RateAmount": $rate_amount, "UserIDFK": $user_idfk, "canCommentOnTasks": $can_comment_on_tasks, "canCreateTasks": $can_create_tasks, "canDeleteTasks": $can_delete_tasks, "canUpdateTasks": $can_update_tasks, "isProjectManager": $is_project_manager, "isTimesheetAllowed": $is_timesheet_allowed, "isTimesheetApprovalRequired": $is_timesheet_approval_required, "isTimesheetApprover": $is_timesheet_approver} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Gets list of Project Timesheet Categories
#
# GET /api/ProjectTimesheetCategory
# operationId: ProjectTimesheetCategory_Get
export def "project-timesheet-category get" [
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
  --project-id: int # Get categories filtered by ProjectID (format: int32)
]: nothing -> record<Categories: table<AccountIDFK: int, BudgetHours: float, CostAmount: float, Name: string, ProjectIDFK: int, RateAmount: float, TimeSheetCategoryIDFK: int, isBillable: bool, isDisabled: bool, isPayable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ProjectID" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ProjectTimesheetCategory" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ProjectID": $project_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Assign a TimeSheetCategory to a Project.
#
# POST /api/ProjectTimesheetCategory
# operationId: ProjectTimesheetCategory_Post
export def "project-timesheet-category create" [
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
  --budget-hours: float # format: double
  --cost-amount: float # format: double
  --project-idfk: int # format: int32
  --rate-amount: float # format: double
  --timesheet-category-idfk: int # format: int32
  --is-billable: oneof<nothing, bool>
  --is-payable: oneof<nothing, bool>
]: any -> record<AccountIDFK: int, BudgetHours: float, CostAmount: float, Name: string, ProjectIDFK: int, RateAmount: float, TimeSheetCategoryIDFK: int, isBillable: bool, isDisabled: bool, isPayable: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/ProjectTimesheetCategory" $auth.query)
  let req_body = {"BudgetHours": $budget_hours, "CostAmount": $cost_amount, "ProjectIDFK": $project_idfk, "RateAmount": $rate_amount, "TimesheetCategoryIDFK": $timesheet_category_idfk, "isBillable": $is_billable, "isPayable": $is_payable} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Gets list of Schedule Assignments.
#
# GET /api/ScheduleAssignment
# operationId: ScheduleAssignment_Get
export def "schedule-assignment get" [
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
  --updated-after: string # Limit results to records updated after the specified date (format: date-time)
  --schedule-date-from: string # Filter for schedule assignement that are on or after a specific date (format: date-time)
  --schedule-date-to: string # Filter for schedules that are on or before a specific date (format: date-time)
  --schedule-series-id: int # Filter to records for a particular Schedule Series (format: int64)
  --user-id: int # The UserID of a schedule user to filter assignments for. Only api users with Admin role can see all schedules across all users. Users with ScheduleUser role can access their own ScheduleSeries. (format: int32)
  --user-email: string # The email of the user who has been scheduled
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --qp-sort: string # Optional sorting instruction. Currently possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc"
]: nothing -> record<PageNumber: int, PageSize: int, ScheduleAssignments: table<AccountIDFK: int, DateCreated: string, DateUpdated: string, Duration: float, ScheduleAssignmentID: int, ScheduleDate: string, ScheduleSeriesIDFK: int, UserIDFK: int>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $updated_after "scalar") (serialize-qp "ScheduleDateFrom" $schedule_date_from "scalar") (serialize-qp "ScheduleDateTo" $schedule_date_to "scalar") (serialize-qp "ScheduleSeriesID" $schedule_series_id "scalar") (serialize-qp "UserID" $user_id "scalar") (serialize-qp "UserEmail" $user_email "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "Sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ScheduleAssignment" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdatedAfter": $updated_after, "ScheduleDateFrom": $schedule_date_from, "ScheduleDateTo": $schedule_date_to, "ScheduleSeriesID": $schedule_series_id, "UserID": $user_id, "UserEmail": $user_email, "pageSize": $page_size, "pageNumber": $page_number, "Sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets list of Schedule Series
#
# GET /api/ScheduleSeries
# operationId: ScheduleSeries_Get
export def "schedule-series get" [
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
  --updated-after: string # Limit results to records updated after the specified date (format: date-time)
  --schedule-start-date-from: string # Filter for schedules that start on or after a specific date (format: date-time)
  --schedule-start-date-to: string # Filter for schedules that start on or before a specific date (format: date-time)
  --schedule-end-date-from: string # Filter for schedules that end on or after a specific date (format: date-time)
  --schedule-end-date-to: string # Filter for schedules that end on or before a specific date (format: date-time)
  --user-id: int # The UserID of a schedule user to filter assignments for. Only api users with Admin role can see all schedules across all users. Users with ScheduleUser role can access their own ScheduleSeries. (format: int32)
  --user-email: string # The email of the user who has been scheduled
  --time-sheet-category-id: int # Filter for schedule records linked to a specific timesheeet category (format: int32)
  --time-sheet-category-name: string # Filter for schedule records with a specific timesheeet category name (exact string match)
  --leave-type-id: int # Filter to records of a particular leave type (format: int32)
  --project-id: int # Filter to only include books linked to a specific project (format: int32)
  --company-id: int # Filter to only include records linked to projects, where that project belongs to a specific customer company (format: int32)
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --qp-sort: string # Optional sorting instruction. Currently possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc"
]: nothing -> record<PageNumber: int, PageSize: int, ScheduleSeries: table<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DateCreated: string, DateUpdated: string, EndDate: string, Firstname: string, HoursPerDay: float, Lastname: string, LeaveTypeIDFK: int, LeaveTypeName: string, Notes: string, ProjectIDFK: int, ProjectTitle: string, ScheduleOnDaysOff: bool, ScheduleSeriesID: int, StartDate: string, TaskIDFK: int, TaskTitle: string, TimeSheetCategoryIDFK: int, TimeSheetCategoryName: string, TotalDuration: float, UpdatedByUserIDFK: int, UserIDFK: int>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $updated_after "scalar") (serialize-qp "ScheduleStartDateFrom" $schedule_start_date_from "scalar") (serialize-qp "ScheduleStartDateTo" $schedule_start_date_to "scalar") (serialize-qp "ScheduleEndDateFrom" $schedule_end_date_from "scalar") (serialize-qp "ScheduleEndDateTo" $schedule_end_date_to "scalar") (serialize-qp "UserID" $user_id "scalar") (serialize-qp "UserEmail" $user_email "scalar") (serialize-qp "TimeSheetCategoryID" $time_sheet_category_id "scalar") (serialize-qp "TimeSheetCategoryName" $time_sheet_category_name "scalar") (serialize-qp "LeaveTypeID" $leave_type_id "scalar") (serialize-qp "ProjectID" $project_id "scalar") (serialize-qp "CompanyID" $company_id "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "Sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/ScheduleSeries" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdatedAfter": $updated_after, "ScheduleStartDateFrom": $schedule_start_date_from, "ScheduleStartDateTo": $schedule_start_date_to, "ScheduleEndDateFrom": $schedule_end_date_from, "ScheduleEndDateTo": $schedule_end_date_to, "UserID": $user_id, "UserEmail": $user_email, "TimeSheetCategoryID": $time_sheet_category_id, "TimeSheetCategoryName": $time_sheet_category_name, "LeaveTypeID": $leave_type_id, "ProjectID": $project_id, "CompanyID": $company_id, "pageSize": $page_size, "pageNumber": $page_number, "Sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a Section
#
# DELETE /api/Section
# operationId: Section_Delete
export def "section delete" [
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
  --section-id: int # format: int64
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SectionID" $section_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Section" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"SectionID": $section_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Gets list of Sections
#
# GET /api/Section
# operationId: Section_Get
export def "section get" [
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
  --project-id: int # Get sections for Project with ProjectID (format: int32)
]: nothing -> record<Sections: table<DisplayOrder: int, EndDate: string, EndDateUTC: string, ProjectIDFK: int, SectionID: int, StartDate: string, StartDateUTC: string, Title: string>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ProjectID" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Section" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ProjectID": $project_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a Section
#
# POST /api/Section
# operationId: Section_Post
export def "section create" [
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
  --end-date-utc: string # format: date-time
  --project-idfk: int # format: int32
  --start-date-utc: string # format: date-time
  --title: string
]: any -> record<DisplayOrder: int, EndDate: string, EndDateUTC: string, ProjectIDFK: int, SectionID: int, StartDate: string, StartDateUTC: string, Title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Section" $auth.query)
  let req_body = {"EndDateUTC": $end_date_utc, "ProjectIDFK": $project_idfk, "StartDateUTC": $start_date_utc, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Delete a Task
#
# DELETE /api/Task
# operationId: Task_Delete
export def "task delete" [
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
  --task-id: int # format: int64
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TaskID" $task_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Task" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"TaskID": $task_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Gets list of Tasks
#
# GET /api/Task
# operationId: Task_Get
export def "task list" [
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
  --updated-after: string # Optional filter to records updated after a specific date. (format: date-time)
  --page-size: int # Number of items per page. Defaults to 20. (format: int32)
  --page-number: int # Page to display. Starts from 1. Defaults to 1 (format: int32)
  --qp-sort: string # Optional sorting instruction. Currently possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc", "SectionTitle", "Title"
  --is-complete: oneof<nothing, bool> # Optional filter to only display tasks linked to a Task Status where isComplete=false, or where isComplete=true
  --project-id: int # Optional filter to only display tasks belonging to a specific ProjectID (format: int32)
]: nothing -> record<PageNumber: int, PageSize: int, Tasks: table<AccountTaskTypeIDFK: int, ActualTime: float, AssignedToUsers: list, DateCompleted: string, DateCreated: string, DateDue: string, DateStart: string, DateUpdated: string, Description: string, DescriptionNoHTML: string, EstimatedEffort: float, PercentComplete: float, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, SectionIDFK: int, SectionTitle: string, Tags: list, TaskID: int, TaskPriorityCode: string, TaskPriorityName: string, TaskStatusCode: string, TaskStatusName: string, Title: string, isCompleteStatus: bool>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $updated_after "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "Sort" $qp_sort "scalar") (serialize-qp "isComplete" $is_complete "scalar") (serialize-qp "ProjectID" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Task" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdatedAfter": $updated_after, "pageSize": $page_size, "pageNumber": $page_number, "Sort": $qp_sort, "isComplete": $is_complete, "ProjectID": $project_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a Task
#
# POST /api/Task
# operationId: Task_Post
# --Tags item shape: {Color?: string, Name?: string}
export def "task create" [
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
  --account-task-type-idfk: int # format: int32
  --assigned-to-user-idf-ks: list<int>
  --date-due: string # format: date-time
  --date-start: string # format: date-time
  --description: string
  --estimated-effort: float # Decimal hours (format: double)
  project_idfk: int # format: int32
  section_idfk: int # format: int32
  --tags: list # Collection of tags specifying Name and Color (Hex) — item shape: {Color?: string, Name?: string}
  --task-priority-code: string
  title: string
]: any -> record<AccountTaskTypeIDFK: int, ActualTime: float, AssignedToUsers: table<AssignedToEmail: string, AssignedToFirstname: string, AssignedToLastname: string, AssignedToUserIDFK: int>, DateCompleted: string, DateCreated: string, DateDue: string, DateStart: string, DateUpdated: string, Description: string, DescriptionNoHTML: string, EstimatedEffort: float, PercentComplete: float, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, SectionIDFK: int, SectionTitle: string, Tags: table<Color: string, Name: string, TagID: int>, TaskID: int, TaskPriorityCode: string, TaskPriorityName: string, TaskStatusCode: string, TaskStatusName: string, Title: string, isCompleteStatus: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Task" $auth.query)
  let req_body = {"AccountTaskTypeIDFK": $account_task_type_idfk, "AssignedToUserIDFKs": $assigned_to_user_idf_ks, "DateDue": $date_due, "DateStart": $date_start, "Description": $description, "EstimatedEffort": $estimated_effort, "ProjectIDFK": $project_idfk, "SectionIDFK": $section_idfk, "Tags": $tags, "TaskPriorityCode": $task_priority_code, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Update a Task.
#
# PUT /api/Task
# operationId: Task_Put
# --Tags item shape: {Color?: string, Name?: string}
export def "task update" [
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
  --assigned-to-user-idfk: list<int>
  --date-due: string # format: date-time
  --date-start: string # format: date-time
  --description: string
  --estimated-effort: float # Decimal hours (format: double)
  fields_to_update: list<string>
  --percent-complete: int # format: int32
  --section-idfk: int # format: int32
  --tags: list # item shape: {Color?: string, Name?: string}
  task_id: int # format: int32
  --task-priority-code: string
  --task-status-code: string
  --title: string
]: any -> record<AccountTaskTypeIDFK: int, ActualTime: float, AssignedToUsers: table<AssignedToEmail: string, AssignedToFirstname: string, AssignedToLastname: string, AssignedToUserIDFK: int>, DateCompleted: string, DateCreated: string, DateDue: string, DateStart: string, DateUpdated: string, Description: string, DescriptionNoHTML: string, EstimatedEffort: float, PercentComplete: float, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, SectionIDFK: int, SectionTitle: string, Tags: table<Color: string, Name: string, TagID: int>, TaskID: int, TaskPriorityCode: string, TaskPriorityName: string, TaskStatusCode: string, TaskStatusName: string, Title: string, isCompleteStatus: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Task" $auth.query)
  let req_body = {"AssignedToUserIDFK": $assigned_to_user_idfk, "DateDue": $date_due, "DateStart": $date_start, "Description": $description, "EstimatedEffort": $estimated_effort, "FieldsToUpdate": $fields_to_update, "PercentComplete": $percent_complete, "SectionIDFK": $section_idfk, "Tags": $tags, "TaskID": $task_id, "TaskPriorityCode": $task_priority_code, "TaskStatusCode": $task_status_code, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Gets minimal list of Tasks for the current user
#
# GET /api/Task/Lookup
# operationId: TaskLookup
export def "task-lookup get" [
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
  --project-id: int # (required) The ProjectID to use when filtering Tasks (format: int32)
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --hide-completed: oneof<nothing, bool> # (optional) true/false to hide completed tasks. Defaults false
  --search: string # (optional) Search string to match against Task title. Performs begins-with match
]: nothing -> record<PageSize: int, hasMore: bool, pageNumber: int, sections: table<SectionTitle: string, tasks: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectID" $project_id "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "hideCompleted" $hide_completed "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Task/Lookup" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"projectID": $project_id, "pageSize": $page_size, "pageNumber": $page_number, "hideCompleted": $hide_completed, "search": $search} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets Task by Task ID
#
# GET /api/Task/{id}
# operationId: Task_GetByID
export def "task get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<AccountTaskTypeIDFK: int, ActualTime: float, AssignedToUsers: table<AssignedToEmail: string, AssignedToFirstname: string, AssignedToLastname: string, AssignedToUserIDFK: int>, DateCompleted: string, DateCreated: string, DateDue: string, DateStart: string, DateUpdated: string, Description: string, DescriptionNoHTML: string, EstimatedEffort: float, PercentComplete: float, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, SectionIDFK: int, SectionTitle: string, Tags: table<Color: string, Name: string, TagID: int>, TaskID: int, TaskPriorityCode: string, TaskPriorityName: string, TaskStatusCode: string, TaskStatusName: string, Title: string, isCompleteStatus: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Task/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets list of Task Statuses
#
# GET /api/TaskStatus
# operationId: TaskStatus_Get
export def "task-status get" [
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
]: nothing -> record<statuses: table<AccountTaskTypeIDFK: int, Color: string, DisplayOrder: int, Name: string, TaskStatusCode: string, TaskTypeName: string, isComplete: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/TaskStatus" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets list of Task Types
#
# GET /api/TaskType
# operationId: TaskType_Get
export def "task-type get" [
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
]: nothing -> record<tasktypes: table<AccountTaskTypeID: int, Icon: string, IconType: string, Name: string, isDefault: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/TaskType" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get List of Taxes configured in the Avaza account.
#
# GET /api/Tax
# operationId: Tax_Get
export def "tax get" [
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
]: nothing -> record<Taxes: table<CalculatedPercent: float, Name: string, TaxCode: string, TaxComponents: list, TaxID: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Tax" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets list of Timsheets
#
# GET /api/Timesheet
# operationId: Timesheet_Get
export def "timesheet list" [
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
  --updated-after: string # format: date-time
  --entry-date-from: string # format: date-time
  --entry-date-to: string # format: date-time
  --user-id: int # The UserID of a timesheet user to filter timesheets for. Only api users with certain higher roles can see timesheets across multiple users. (format: int32)
  --user-email: string
  --category-name: string
  --project-id: int # format: int32
  --is-billable: oneof<nothing, bool>
  --is-invoiced: oneof<nothing, bool>
  --is-timer-running: oneof<nothing, bool>
  --page-size: int # Number of items per page (max 1000) (format: int32)
  --page-number: int # Page to display. Starts from 1. (format: int32)
  --include-invoice-details: oneof<nothing, bool> # Defaults to false. When true, the InvoiceIDFK value will be included in the response.
  --qp-sort: string # Optional sorting instruction. Currently possible values: "DateUpdated", "DateCreated", "DateUpdated desc", "DateCreated desc","EntryDate", "EntryDate desc", "StartTimeLocal","StartTimeLocal desc", "TimeSheetEntryID", "TimeSheetEntryID desc"
]: nothing -> record<PageNumber: int, PageSize: int, Timesheets: table<ApprovedBy: string, CategoryName: string, CustomMetadata: string, CustomerIDFK: int, CustomerName: string, DateApproved: string, DateCreated: string, DateUpdated: string, Duration: float, Email: string, EndTimeLocal: string, EndTimeUTC: string, EntryDate: string, Firstname: string, HasTimer: bool, InvoiceIDFK: int, InvoiceLineItemIDFK: int, Lastname: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, StartTimeLocal: string, StartTimeUTC: string, TaskIDFK: int, TaskTitle: string, TimerStartedAtUTC: string, TimesheetCategoryIDFK: int, TimesheetEntryApprovalStatusCode: string, TimesheetEntryID: int, TimesheetUserTimeZone: string, UserIDFK: int, isBillable: bool, isInvoiced: bool>, TotalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UpdatedAfter" $updated_after "scalar") (serialize-qp "EntryDateFrom" $entry_date_from "scalar") (serialize-qp "EntryDateTo" $entry_date_to "scalar") (serialize-qp "UserID" $user_id "scalar") (serialize-qp "UserEmail" $user_email "scalar") (serialize-qp "CategoryName" $category_name "scalar") (serialize-qp "ProjectID" $project_id "scalar") (serialize-qp "isBillable" $is_billable "scalar") (serialize-qp "isInvoiced" $is_invoiced "scalar") (serialize-qp "isTimerRunning" $is_timer_running "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "includeInvoiceDetails" $include_invoice_details "scalar") (serialize-qp "Sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Timesheet" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UpdatedAfter": $updated_after, "EntryDateFrom": $entry_date_from, "EntryDateTo": $entry_date_to, "UserID": $user_id, "UserEmail": $user_email, "CategoryName": $category_name, "ProjectID": $project_id, "isBillable": $is_billable, "isInvoiced": $is_invoiced, "isTimerRunning": $is_timer_running, "pageSize": $page_size, "pageNumber": $page_number, "includeInvoiceDetails": $include_invoice_details, "Sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a new Timesheet Entry
#
# POST /api/Timesheet
# operationId: Timesheet_Post
export def "timesheet create" [
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
  --custom-metadata: string # Optional. free nvarchar field available via Api to store any additional metadata against a timesheet. We suggest you use Json or your preferred serialisation format. 1000 characters max.
  --duration: float # The duration of the timesheet, in decimal hours. If null or 0, a timer will be started. (format: double)
  --entry-date: string # The date of the timesheet entry, with an optional start time component. (format: date-time)
  --notes: string # Timesheet Notes
  --project-idfk: int # The project to associate the timesheet with. (format: int32)
  --task-idfk: int # Optional. Link the timesheet to a specific task (format: int32)
  --timesheet-category-idfk: int # The Project timesheet category to link the timesheet to (format: int32)
  --user-idfk: int # UserID for a Timesheet user in Avaza (format: int32)
  --has-start-end-time: oneof<nothing, bool> # If true, the start time will be take from the time component of the Entry Date field, and the end time will be calculated by adding the Duration to the StartDate
  --is-invoiced: oneof<nothing, bool> # Optional. False by default. Allows you to mark the timesheet as invoiced in an external system.
]: any -> record<ApprovedBy: string, CategoryName: string, CustomMetadata: string, CustomerIDFK: int, CustomerName: string, DateApproved: string, DateCreated: string, DateUpdated: string, Duration: float, Email: string, EndTimeLocal: string, EndTimeUTC: string, EntryDate: string, Firstname: string, HasTimer: bool, InvoiceIDFK: int, InvoiceLineItemIDFK: int, Lastname: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, StartTimeLocal: string, StartTimeUTC: string, TaskIDFK: int, TaskTitle: string, TimerStartedAtUTC: string, TimesheetCategoryIDFK: int, TimesheetEntryApprovalStatusCode: string, TimesheetEntryID: int, TimesheetUserTimeZone: string, UserIDFK: int, isBillable: bool, isInvoiced: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Timesheet" $auth.query)
  let req_body = {"CustomMetadata": $custom_metadata, "Duration": $duration, "EntryDate": $entry_date, "Notes": $notes, "ProjectIDFK": $project_idfk, "TaskIDFK": $task_idfk, "TimesheetCategoryIDFK": $timesheet_category_idfk, "UserIDFK": $user_idfk, "hasStartEndTime": $has_start_end_time, "isInvoiced": $is_invoiced} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Update a Timesheet
#
# PUT /api/Timesheet
# operationId: Timesheet_Put
export def "timesheet update" [
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
  --custom-metadata: string # Optional. free nvarchar field available via Api to store any additional metadata against a timesheet. We suggest you use Json or your preferred serialisation format. 1000 characters max.
  --duration: float # format: double
  --entry-date: string # format: date-time
  fields_to_update: list<string>
  --notes: string
  project_idfk: int # format: int32
  --task-idfk: int # format: int32
  time_sheet_entry_id: int # format: int64
  --timesheet-category-idfk: int # format: int32
  --has-start-end-time: oneof<nothing, bool>
]: any -> record<ApprovedBy: string, CategoryName: string, CustomMetadata: string, CustomerIDFK: int, CustomerName: string, DateApproved: string, DateCreated: string, DateUpdated: string, Duration: float, Email: string, EndTimeLocal: string, EndTimeUTC: string, EntryDate: string, Firstname: string, HasTimer: bool, InvoiceIDFK: int, InvoiceLineItemIDFK: int, Lastname: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, StartTimeLocal: string, StartTimeUTC: string, TaskIDFK: int, TaskTitle: string, TimerStartedAtUTC: string, TimesheetCategoryIDFK: int, TimesheetEntryApprovalStatusCode: string, TimesheetEntryID: int, TimesheetUserTimeZone: string, UserIDFK: int, isBillable: bool, isInvoiced: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Timesheet" $auth.query)
  let req_body = {"CustomMetadata": $custom_metadata, "Duration": $duration, "EntryDate": $entry_date, "FieldsToUpdate": $fields_to_update, "Notes": $notes, "ProjectIDFK": $project_idfk, "TaskIDFK": $task_idfk, "TimeSheetEntryID": $time_sheet_entry_id, "TimesheetCategoryIDFK": $timesheet_category_idfk, "hasStartEndTime": $has_start_end_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Delete a Timesheet Entry
#
# DELETE /api/Timesheet/{id}
# operationId: Timesheet_Delete
export def "timesheet delete" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Timesheet/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets a Timesheet Entry by Timesheet ID
#
# GET /api/Timesheet/{id}
# operationId: Timesheet_GetByID
export def "timesheet get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<ApprovedBy: string, CategoryName: string, CustomMetadata: string, CustomerIDFK: int, CustomerName: string, DateApproved: string, DateCreated: string, DateUpdated: string, Duration: float, Email: string, EndTimeLocal: string, EndTimeUTC: string, EntryDate: string, Firstname: string, HasTimer: bool, InvoiceIDFK: int, InvoiceLineItemIDFK: int, Lastname: string, Notes: string, ProjectCode: string, ProjectIDFK: int, ProjectTitle: string, StartTimeLocal: string, StartTimeUTC: string, TaskIDFK: int, TaskTitle: string, TimerStartedAtUTC: string, TimesheetCategoryIDFK: int, TimesheetEntryApprovalStatusCode: string, TimesheetEntryID: int, TimesheetUserTimeZone: string, UserIDFK: int, isBillable: bool, isInvoiced: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Timesheet/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Submit Timesheets for Approval.
#
# POST /api/TimesheetSubmission
# operationId: TimesheetSubmission_Post
export def "timesheet-submission create" [
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
  --send-notifications: oneof<nothing, bool> # Send email alerts to timesheet approvers. Defaults to true
  --whole-week-of: string # A date (yyyy-MM-dd) that falls within a Week to have all timesheets in that week submitted. Respects the First Day of Week setting in your account Timesheet Settings to determine the week range. (format: date-time)
  --whole-day-of: string # A date (yyyy-MM-dd) to submit all timesheets on this day (format: date-time)
  --user-id: int # The user to submit timesheets for. Defaults to current user. Only allowed to be different from the current user when the current user has rights to Impersonate other users. (format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SendNotifications" $send_notifications "scalar") (serialize-qp "WholeWeekOf" $whole_week_of "scalar") (serialize-qp "WholeDayOf" $whole_day_of "scalar") (serialize-qp "UserID" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/TimesheetSubmission" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"SendNotifications": $send_notifications, "WholeWeekOf": $whole_week_of, "WholeDayOf": $whole_day_of, "UserID": $user_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Gets Basic Summary of Timesheet Statistics
#
# GET /api/TimesheetSummary
# operationId: TimesheetSummary_Get
export def "timesheet-summary get" [
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
  --model-group-by: list<string> # (Optional) Combine one, two or three levels of Grouping. Combine these possible grouping values: "Customer", "Project", "Category", "User", "Task", "Year", "Month", "Day", "Week".
  --model-entry-date-from: string # (Required) Filter for timesheets greater or equal to the specified date. e.g. 2019-01-25. You can optionally include a time component, otherwise it assumes 00:00 (format: date-time)
  --model-entry-date-to: string # (Required) Filter for timesheets with an entry date smaller or equal to the specified date. e.g. 2019-01-25. You can optionally include a time component, otherwise it assumes 00:00 (format: date-time)
  --model-user-id: list<int> # (Optional) Defaults to the current user. Provide one or more UserIDs of Users whose timesheets should be retrieved. If the current user doesn't have impersonation rights, then they will only see their own data.
  --model-project-id: int # (Optional) Filter by Project (format: int32)
  --model-is-billable: oneof<nothing, bool> # (Optional) Filter by the billable status of Timesheets.
  --model-is-invoiced: oneof<nothing, bool> # (Optional) Filter for timesheets by whether they have been Invoiced or not.
]: nothing -> record<BillableHours: float, EntryDateFrom: string, EntryDateTo: string, GroupData: table<BillableHours: float, GroupData: list, GroupID: string, GroupName: string, TotalHours: float>, GroupingLevels: list<string>, TotalHours: float, UserID: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model.groupBy" $model_group_by "multi") (serialize-qp "model.entryDateFrom" $model_entry_date_from "scalar") (serialize-qp "model.entryDateTo" $model_entry_date_to "scalar") (serialize-qp "model.userID" $model_user_id "multi") (serialize-qp "model.projectID" $model_project_id "scalar") (serialize-qp "model.isBillable" $model_is_billable "scalar") (serialize-qp "model.isInvoiced" $model_is_invoiced "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/TimesheetSummary" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"model.groupBy": $model_group_by, "model.entryDateFrom": $model_entry_date_from, "model.entryDateTo": $model_entry_date_to, "model.userID": $model_user_id, "model.projectID": $model_project_id, "model.isBillable": $model_is_billable, "model.isInvoiced": $model_is_invoiced} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets the Running Timer if there is one for a user.
#
# GET /api/TimesheetTimer
# operationId: TimesheetTimer_GetRunningTimer
export def "timesheet-timer get-running" [
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
  --user-id: int # Optional - User ID number if impersonating a different user. Otherwise assumes the current user. Only users with certain security roles have permission to impersonate other users (format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UserID" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/TimesheetTimer" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"UserID": $user_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Stop the timer running on an existing Timesheet Entry
#
# DELETE /api/TimesheetTimer/{id}
# operationId: TimesheetTimer_StopTimer
export def "timesheet-timer stop" [
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
  --accept: string@accept-completer # Response content type
  --user-id: int # Optional - User ID number if impersonating a different user. Otherwise assumes the current user. Only users with certain security roles have permission to impersonate other users (format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "UserID" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/TimesheetTimer/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"UserID": $user_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Starts a Timer running on an existing Timesheet Entry
#
# POST /api/TimesheetTimer/{id}
# operationId: TimesheetTimer_StartTimer
export def "timesheet-timer start" [
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
  --accept: string@accept-completer # Response content type
  --user-id: int # Optional - User ID number if impersonating a different user. Otherwise assumes the current user. Only users with certain security roles have permission to impersonate other users (format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "UserID" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/TimesheetTimer/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"UserID": $user_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Get Collection of Users who have roles in the current Avaza account.
#
# GET /api/UserProfile
# operationId: UserProfile_Get
export def "user-profile get" [
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
  --roles: string # Optional list of comma separated role codes to filter users by (e.g. "TimesheetUser,Admin")
  --tags: string
  --current-user-only: oneof<nothing, bool> # Optional boolean (true/false) to filter to only show current authenticated user (always true for non Admin/InvoiceManager users)
  --company-idfk: int # Optionally filter by Company ID (format: int32)
]: nothing -> record<Users: table<AccountIDFK: int, CompanyIDFK: int, CompanyName: string, DefaultBillableRate: float, DefaultCostRate: float, Email: string, Firstname: string, FridayAvailableHours: float, IANATimezone: string, Lastname: string, Mobile: string, MondayAvailableHours: float, Phone: string, PositionTitle: string, Roles: list, SaturdayAvailableHours: float, SundayAvailableHours: float, Tags: list, ThursdayAvailableHours: float, TimeZone: string, TuesdayAvailableHours: float, UserID: int, WednesdayAvailableHours: float, isTeamMember: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Roles" $roles "scalar") (serialize-qp "Tags" $tags "scalar") (serialize-qp "CurrentUserOnly" $current_user_only "scalar") (serialize-qp "CompanyIDFK" $company_idfk "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/UserProfile" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Roles": $roles, "Tags": $tags, "CurrentUserOnly": $current_user_only, "CompanyIDFK": $company_idfk} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete webhook subscription by URL
#
# DELETE /api/Webhook
# operationId: Webhook_DeleteByUrl
export def "webhook delete-by-url" [
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
  --target-url: string # Target URL that should be used to delete subscriptions
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "target_url" $target_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/Webhook" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"target_url": $target_url} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get list of Webhook Subscriptions
#
# GET /api/Webhook
# operationId: Webhook_Get
export def "webhook list" [
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
]: nothing -> record<Webhooks: table<EventCode: string, NotificationURL: string, SubscriptionID: int, UserIDFK: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Webhook" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Subscribe to Webhook. On success, returns ID of webhook subscription.
#
# POST /api/Webhook
# operationId: Webhook_Post
export def "webhook create" [
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
  event: string # The event code to be notified about. Possible values: company_created, contact_created, invoice_created, invoice_sent, project_created, task_created
  --secret: string # Optional Secret string (255 char max). If provided, the secret will be BASE 64 encoded and used as a basic authentication http header with webhook notifications. i.e. Authorization Basic [BASE64 of Secret]"
  target_url: string # The URL that should be notified of the event.
]: any -> record<ID: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Webhook" $auth.query)
  let req_body = {"event": $event, "secret": $secret, "target_url": $target_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete Webhook Subscription by ID
#
# DELETE /api/Webhook/{id}
# operationId: Webhook_Delete
export def "webhook delete" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Webhook/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get Webhook Subscription by SubscriptionID
#
# GET /api/Webhook/{id}
# operationId: Webhook_GetByID
export def "webhook get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<Webhooks: table<EventCode: string, NotificationURL: string, SubscriptionID: int, UserIDFK: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/Webhook/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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
