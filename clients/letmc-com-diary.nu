# Auto-generated client for agentOS API V3, Diary Call Group v3-diary
# Source: https://api.apis.guru/v2/specs/letmc.com/diary/v3-diary/openapi.json
# Auth: --token flag or $env.AGENTOS_API_V3_DIARY_CALL_GROUP_TOKEN

const BASE_URL = "https://live-api.letmc.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AGENTOS_API_V3_DIARY_CALL_GROUP_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "apikey" => { {scheme: $scheme, headers: {"ApiKey": $token_val}, query: "", location: "header"} }
    "basic" => { {scheme: $scheme, headers: {"Authorization": $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
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

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://live-api.letmc.com"] }
def auth-scheme-completer [] { ["apikey" "basic" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def accept-completer-1 [] { ["application/json" "text/json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["diary-controller-get-allocations" "diary-controller-delete-appointment" "diary-controller-get-appointment" "diary-controller-post-appointment" "diary-controller-put-appointment" "diary-controller-add-feedback" "diary-controller-cancel-appointment" "diary-controller-get-appointments-between-dates" "diary-controller-get-appointment-types" "company-controller-get-branches" "get-v3-diary-short-name-company-branches-branch-id" "diary-controller-get-recurring-appointments" "diary-controller-search-guest" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
export def "diary-controller-get-allocations" [
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
  --preferred-date: string # The date to search from (required, format: date-time)
  --appointment-type: string # The unique appointment type identifier (required)
  --lettings: oneof<nothing, bool> # Sales or Lettings property?
  --property-identifier: string # The unique property identifier (Sales or Lettings) determines branch and property type
  --branch-id: string # Branch ID to check appointments (required if no property submitted)
]: nothing -> oneof<table<End: string, StaffID: string, StaffName: string, Start: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  if ($preferred_date == null) { error make --unspanned { msg: "required query parameter 'preferredDate' missing: pass --preferred-date" } }
  if ($appointment_type == null) { error make --unspanned { msg: "required query parameter 'appointmentType' missing: pass --appointment-type" } }
  let qp = [(serialize-qp "preferredDate" $preferred_date "scalar") (serialize-qp "appointmentType" $appointment_type "scalar") (serialize-qp "lettings" $lettings "scalar") (serialize-qp "propertyIdentifier" $property_identifier "scalar") (serialize-qp "branchID" $branch_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/allocations") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"preferredDate": $preferred_date, "appointmentType": $appointment_type, "lettings": $lettings, "propertyIdentifier": $property_identifier, "branchID": $branch_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete an existing appointment using its unique identifier
#
# DELETE /v3/diary/{shortName}/appointment
# operationId: DiaryController_DeleteAppointment
export def "diary-controller-delete-appointment" [
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
  --appointment-id: string # The unique appointment id (required)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  if ($appointment_id == null) { error make --unspanned { msg: "required query parameter 'appointmentID' missing: pass --appointment-id" } }
  let qp = [(serialize-qp "appointmentID" $appointment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/appointment") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"appointmentID": $appointment_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get an appointment by ID
#
# GET /v3/diary/{shortName}/appointment
# operationId: DiaryController_GetAppointment
export def "diary-controller-get-appointment" [
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
  --appointment-id: string # Appointment ID (required)
]: nothing -> oneof<record<AppointmentType: string, Cancelled: bool, Comment: string, CreatedAt: string, CreatedBy: string, ETag: string, End: string, LinkedProperties: table<Address1: string, Address2: string, Address3: string, Address4: string, AddressFlatRoomNumber: string, AddressNumber: string, ETag: string, LatestTenancy: record, MainLandlord: record, OID: string, Postcode: string>, NextRecurringDate: string, OID: string, Recurrence: int, RecurrenceType: string, RemindAt: string, RemindBefore: string, Staff: string, Start: string, Subject: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  if ($appointment_id == null) { error make --unspanned { msg: "required query parameter 'appointmentID' missing: pass --appointment-id" } }
  let qp = [(serialize-qp "appointmentID" $appointment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/appointment") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"appointmentID": $appointment_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Post an appointment into a valid diary allocation
#
# POST /v3/diary/{shortName}/appointment
# operationId: DiaryController_PostAppointment
export def "diary-controller-post-appointment" [
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
  --property-identifier: list<string> # The unique property identifier (Sales or Lettings) (required)
  --lettings: oneof<nothing, bool> # Sales or Lettings property?
  --allocation-details: record # Represents a viewing booking slot — shape: {End?: string, StaffID?: string, StaffName?: string, Start?: string}
  --appointment-type: string # The Appointment Type ID
  --extra-comments: string # Additional appointment comments
  --guests: list # A collection of guests linked to the appointment. If none leave empty — item shape: {AllowMarketingCorrespondence?: bool, EmailAddress?: string, Forename?: string, MobilePhone?: string, OID?: string, Surname?: string}
  --subject: string # The subject of the appointment
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  if ($property_identifier == null) { error make --unspanned { msg: "required query parameter 'propertyIdentifier' missing: pass --property-identifier" } }
  let qp = [(serialize-qp "propertyIdentifier" $property_identifier "multi") (serialize-qp "lettings" $lettings "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/appointment") $qp $auth.query)
  let req_body = {"AllocationDetails": $allocation_details, "AppointmentType": $appointment_type, "ExtraComments": $extra_comments, "Guests": $guests, "Subject": $subject} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"propertyIdentifier": $property_identifier, "lettings": $lettings} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update an existing appointment using its unique identifier
#
# PUT /v3/diary/{shortName}/appointment
# operationId: DiaryController_PutAppointment
export def "diary-controller-put-appointment" [
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
  --appointment-id: string # The unique appointment id (required)
  --lettings: oneof<nothing, bool> # Sales or Lettings property?
  --allow-marketing-correspondence: oneof<nothing, bool> # Sales or Lettings property?
  --allocation-details: record # Represents a viewing booking slot — shape: {End?: string, StaffID?: string, StaffName?: string, Start?: string}
  --appointment-type: string # The Appointment Type ID
  --extra-comments: string # Additional appointment comments
  --guests: list # A collection of guests linked to the appointment. If none leave empty — item shape: {AllowMarketingCorrespondence?: bool, EmailAddress?: string, Forename?: string, MobilePhone?: string, OID?: string, Surname?: string}
  --subject: string # The subject of the appointment
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  if ($appointment_id == null) { error make --unspanned { msg: "required query parameter 'appointmentID' missing: pass --appointment-id" } }
  let qp = [(serialize-qp "appointmentID" $appointment_id "scalar") (serialize-qp "lettings" $lettings "scalar") (serialize-qp "AllowMarketingCorrespondence" $allow_marketing_correspondence "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/appointment") $qp $auth.query)
  let req_body = {"AllocationDetails": $allocation_details, "AppointmentType": $appointment_type, "ExtraComments": $extra_comments, "Guests": $guests, "Subject": $subject} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"appointmentID": $appointment_id, "lettings": $lettings, "AllowMarketingCorrespondence": $allow_marketing_correspondence} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Submit appointment feedback
#
# POST /v3/diary/{shortName}/appointment/feedback
# operationId: DiaryController_AddFeedback
export def "diary-controller-add-feedback" [
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
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/appointment/feedback") $auth.query)
  let req_body = {"AppointmentID": $appointment_id, "Feedback": $feedback, "PropertyID": $property_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Cancel an existing appointment using its unique identifier
#
# PATCH /v3/diary/{shortName}/appointment/{appointmentID}/cancel
# operationId: DiaryController_CancelAppointment
export def "diary-controller-cancel-appointment" [
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
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  if ($appointment_id | is-empty) { error make --unspanned { msg: "path parameter 'appointmentID' must be non-empty" } }
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), appointment_id: (encode-path-segment $appointment_id)} | format pattern "/v3/diary/{short_name}/appointment/{appointment_id}/cancel") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req null $insecure $raw $allow_errors $full [200]
}

# A collection of diary appointments linked to a company filtered between specific dates and by appointment type
#
# GET /v3/diary/{shortName}/appointmentsbetweendates
# operationId: DiaryController_GetAppointmentsBetweenDates
export def "diary-controller-get-appointments-between-dates" [
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
  --branch-id: string # The unique ID of the Branch (required)
  --start-date: string # The search from date (required, format: date-time)
  --end-date: string # The search to date (required, format: date-time)
  --appointment-types-to-search: list<string> # The appointment IDs to search for (required)
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record<Count: int, Data: table<AppointmentType: string, Cancelled: bool, Comment: string, CreatedAt: string, CreatedBy: string, ETag: string, End: string, LinkedProperties: list, NextRecurringDate: string, OID: string, Recurrence: int, RecurrenceType: string, RemindAt: string, RemindBefore: string, Staff: string, Start: string, Subject: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  if ($branch_id == null) { error make --unspanned { msg: "required query parameter 'branchID' missing: pass --branch-id" } }
  if ($start_date == null) { error make --unspanned { msg: "required query parameter 'startDate' missing: pass --start-date" } }
  if ($end_date == null) { error make --unspanned { msg: "required query parameter 'endDate' missing: pass --end-date" } }
  if ($appointment_types_to_search == null) { error make --unspanned { msg: "required query parameter 'appointmentTypesToSearch' missing: pass --appointment-types-to-search" } }
  if ($offset == null) { error make --unspanned { msg: "required query parameter 'offset' missing: pass --offset" } }
  if ($count == null) { error make --unspanned { msg: "required query parameter 'count' missing: pass --count" } }
  let qp = [(serialize-qp "branchID" $branch_id "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "appointmentTypesToSearch" $appointment_types_to_search "multi") (serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/appointmentsbetweendates") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"branchID": $branch_id, "startDate": $start_date, "endDate": $end_date, "appointmentTypesToSearch": $appointment_types_to_search, "offset": $offset, "count": $count} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# A collection of all diary appointment types
#
# GET /v3/diary/{shortName}/appointmenttypes
# operationId: DiaryController_GetAppointmentTypes
export def "diary-controller-get-appointment-types" [
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record<Count: int, Data: table<ETag: string, Name: string, OID: string, SystemType: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  if ($offset == null) { error make --unspanned { msg: "required query parameter 'offset' missing: pass --offset" } }
  if ($count == null) { error make --unspanned { msg: "required query parameter 'count' missing: pass --count" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/appointmenttypes") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "count": $count} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# All branches defined for a company
#
# GET /v3/diary/{shortName}/company/branches
# operationId: CompanyController_GetBranches
export def "company-controller-get-branches" [
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
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  if ($offset == null) { error make --unspanned { msg: "required query parameter 'offset' missing: pass --offset" } }
  if ($count == null) { error make --unspanned { msg: "required query parameter 'count' missing: pass --count" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/company/branches") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "count": $count} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a specific branch given its unique Object ID (OID)
#
# GET /v3/diary/{shortName}/company/branches/{branchID}
export def "get-v3-diary-short-name-company-branches-branch-id" [
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
]: nothing -> oneof<record<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  if ($branch_id | is-empty) { error make --unspanned { msg: "path parameter 'branchID' must be non-empty" } }
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), branch_id: (encode-path-segment $branch_id)} | format pattern "/v3/diary/{short_name}/company/branches/{branch_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Retrieves all recurring appointments:-
#
# GET /v3/diary/{shortName}/recurringappointment
# operationId: DiaryController_GetRecurringAppointments
export def "diary-controller-get-recurring-appointments" [
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
  --branch-id: string # The unique ID of the Branch (required)
  --appointment-types-to-search: list<string> # The appointment IDs to search for (required)
  --offset: int # The index of the first item to return (required, format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (required, format: int32)
]: nothing -> oneof<record<Count: int, Data: table<AppointmentType: string, Cancelled: bool, Comment: string, CreatedAt: string, CreatedBy: string, ETag: string, End: string, LinkedProperties: list, NextRecurringDate: string, OID: string, Recurrence: int, RecurrenceType: string, RemindAt: string, RemindBefore: string, Staff: string, Start: string, Subject: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($short_name | is-empty) { error make --unspanned { msg: "path parameter 'shortName' must be non-empty" } }
  if ($branch_id == null) { error make --unspanned { msg: "required query parameter 'branchID' missing: pass --branch-id" } }
  if ($appointment_types_to_search == null) { error make --unspanned { msg: "required query parameter 'appointmentTypesToSearch' missing: pass --appointment-types-to-search" } }
  if ($offset == null) { error make --unspanned { msg: "required query parameter 'offset' missing: pass --offset" } }
  if ($count == null) { error make --unspanned { msg: "required query parameter 'count' missing: pass --count" } }
  let qp = [(serialize-qp "branchID" $branch_id "scalar") (serialize-qp "appointmentTypesToSearch" $appointment_types_to_search "multi") (serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v3/diary/{short_name}/recurringappointment") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"branchID": $branch_id, "appointmentTypesToSearch": $appointment_types_to_search, "offset": $offset, "count": $count} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Match Guest Parameters with existing applicants
#
# GET /v3/diary/{shortname}/{branchID}/guest/search
# operationId: DiaryController_SearchGuest
export def "diary-controller-search-guest" [
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
  --forename: string # required
  --emailaddress: string # required
  --surname: string # required
  --offset: int # required, format: int32
  --count: int # required, format: int32
]: nothing -> oneof<record<Count: int, Data: table<ContactMobile: string, EmailAddress: string, Forename: string, OID: string, Surname: string>, Links: table<Href: string, Method: string, Relationship: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($shortname | is-empty) { error make --unspanned { msg: "path parameter 'shortname' must be non-empty" } }
  if ($branch_id | is-empty) { error make --unspanned { msg: "path parameter 'branchID' must be non-empty" } }
  if ($forename == null) { error make --unspanned { msg: "required query parameter 'forename' missing: pass --forename" } }
  if ($emailaddress == null) { error make --unspanned { msg: "required query parameter 'emailaddress' missing: pass --emailaddress" } }
  if ($surname == null) { error make --unspanned { msg: "required query parameter 'surname' missing: pass --surname" } }
  if ($offset == null) { error make --unspanned { msg: "required query parameter 'offset' missing: pass --offset" } }
  if ($count == null) { error make --unspanned { msg: "required query parameter 'count' missing: pass --count" } }
  let qp = [(serialize-qp "forename" $forename "scalar") (serialize-qp "emailaddress" $emailaddress "scalar") (serialize-qp "surname" $surname "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({shortname: (encode-path-segment $shortname), branch_id: (encode-path-segment $branch_id)} | format pattern "/v3/diary/{shortname}/{branch_id}/guest/search") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"forename": $forename, "emailaddress": $emailaddress, "surname": $surname, "offset": $offset, "count": $count} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
