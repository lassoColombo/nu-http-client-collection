# Auto-generated client for Call Control API v2015-11-01
# Source: https://api.apis.guru/v2/specs/callcontrol.com/2015-11-01/swagger.json
# Auth: --token flag or $env.CALL_CONTROL_API_TOKEN

const BASE_URL = "https://api.callcontrol.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CALL_CONTROL_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "apikey" => { {scheme: $scheme, headers: {apiKey: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.callcontrol.com"] }
def auth-scheme-completer [] { ["apikey"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json"] }
def block-behavior-completer [] { ["allow" "block" "voiceMail"] }
def caller-type-completer [] { ["Business" "Callback" "Collection_Agency" "Fax_Machine" "Fund_Raiser" "Junk_Fax" "NotSpam" "Other_Commercial" "Political" "Prank_Call" "Reminder_Notification_Call" "RoboCall" "Scam" "Spam_Text" "Surveyor" "Telemarketing" "Unknown" "VOIP"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "2015-11-01-complaints get" } } | get name | first)
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

# Complaints: Free service (with registration), providing community and government complaint lookup by phone number for up to 2,000 queries per month. Details include number complaint rates from (FTC, FCC, IRS, Indiana Attorney General) and key entity tag extractions from complaints.
#
# GET /api/2015-11-01/Complaints/{phoneNumber}
# operationId: Complaints_Complaints
export def "2015-11-01-complaints get" [
  phone_number: string
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
]: nothing -> record<ComplaintsByEntity: record, LastComplaintDate: string, ReportedCallerName: string, Tags: list<string>, TotalNumberOfComplaints: int> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($phone_number | is-empty) { error make --unspanned { msg: "path parameter 'phoneNumber' must be non-empty" } }
  let full_url = (build-url $base ({phone_number: (encode-path-segment $phone_number)} | format pattern "/api/2015-11-01/Complaints/{phone_number}") $auth.query)
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

# Enterprise GET: GetUser Returns the current information from the user; try 12066194123 as demo
#
# GET /api/2015-11-01/Enterprise/GetUser/{phoneNumber}
# operationId: EnterpriseApi_GetUser
export def "2015-11-01-enterprise-get-user get" [
  phone_number: string
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
]: nothing -> record<Age: int, BlackList: list<string>, BlockBehavior: string, BreakThroughQhWithMultipleCalls: bool, Email: string, FirstName: string, Gender: string, LastName: string, MiddleName: string, PhoneNumbeRegion: string, PhoneNumber: string, QuietHourList: table<DayOfWeekList: list, DurationMin: int, StartHourLocal: int, StartMinLocal: int, TimeZoneName: string>, Salutation: string, Suffix: string, UseCommunityBlacklist: bool, WhiteList: list<string>, WhiteListBreaksQh: bool> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($phone_number | is-empty) { error make --unspanned { msg: "path parameter 'phoneNumber' must be non-empty" } }
  let full_url = (build-url $base ({phone_number: (encode-path-segment $phone_number)} | format pattern "/api/2015-11-01/Enterprise/GetUser/{phone_number}") $auth.query)
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

# Enterprise GET: ShouldBlock Simple Enteprise which returns a call block proceed decision.
#
# GET /api/2015-11-01/Enterprise/ShouldBlock/{phoneNumber}/{userPhoneNumber}
# operationId: EnterpriseApi_ShouldBlock
export def "2015-11-01-enterprise-should-block get" [
  phone_number: string
  user_phone_number: string
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
  if ($phone_number | is-empty) { error make --unspanned { msg: "path parameter 'phoneNumber' must be non-empty" } }
  if ($user_phone_number | is-empty) { error make --unspanned { msg: "path parameter 'userPhoneNumber' must be non-empty" } }
  let full_url = (build-url $base ({phone_number: (encode-path-segment $phone_number), user_phone_number: (encode-path-segment $user_phone_number)} | format pattern "/api/2015-11-01/Enterprise/ShouldBlock/{phone_number}/{user_phone_number}") $auth.query)
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

# UpsertUser: insert or update all properties from a user PhoneNumber WhiteList (list of phone numbers to whitelist) BlackList (list of phone numbers to blacklist) QuietHourList (list of quiet hour objects) UseCommunityBlacklist (enable / disable community blacklist) default true BreakThroughQhWithMultipleCalls (break through quiet hours with two calls in 3 minutes) WhiteListBreaksQh (break through quiet hours for whitelist)
#
# POST /api/2015-11-01/Enterprise/UpsertUser
# operationId: EnterpriseApi_UpsertUser
# --QuietHourList item shape: {DayOfWeekList?: list<string>, DurationMin?: int, StartHourLocal?: int, StartMinLocal?: int, TimeZoneName?: string}
export def "2015-11-01-enterprise-upsert-user update" [
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
  --age: int # format: int32
  --black-list: list<string>
  --block-behavior: string@block-behavior-completer
  --break-through-qh-with-multiple-calls: oneof<nothing, bool>
  --email: string
  --first-name: string
  --gender: string
  --last-name: string
  --middle-name: string
  --phone-numbe-region: string
  --phone-number: string
  --quiet-hour-list: list # item shape: {DayOfWeekList?: list<string>, DurationMin?: int, StartHourLocal?: int, StartMinLocal?: int, TimeZoneName?: string}
  --salutation: string
  --suffix: string
  --use-community-blacklist: oneof<nothing, bool>
  --white-list: list<string>
  --white-list-breaks-qh: oneof<nothing, bool>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/2015-11-01/Enterprise/UpsertUser" $auth.query)
  let req_body = {"Age": $age, "BlackList": $black_list, "BlockBehavior": $block_behavior, "BreakThroughQhWithMultipleCalls": $break_through_qh_with_multiple_calls, "Email": $email, "FirstName": $first_name, "Gender": $gender, "LastName": $last_name, "MiddleName": $middle_name, "PhoneNumbeRegion": $phone_numbe_region, "PhoneNumber": $phone_number, "QuietHourList": $quiet_hour_list, "Salutation": $salutation, "Suffix": $suffix, "UseCommunityBlacklist": $use_community_blacklist, "WhiteList": $white_list, "WhiteListBreaksQh": $white_list_breaks_qh} | compact
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

# Report: report spam calls received to better tune our algorithms based upon spam calls you receive
#
# POST /api/2015-11-01/Report
# operationId: Reputation_Report
export def "2015-11-01-report create-reputation" [
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
  --call-time: string # format: date-time
  --caller-type: string@caller-type-completer
  --comment: string
  --ip-address: string
  --latitude: float # format: double
  --longitude: float # format: double
  --phone-number: string
  --reported-caller-id: string
  --reported-caller-name: string
  --reporter: string
  --unwanted-call: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/2015-11-01/Report" $auth.query)
  let req_body = {"CallTime": $call_time, "CallerType": $caller_type, "Comment": $comment, "IpAddress": $ip_address, "Latitude": $latitude, "Longitude": $longitude, "PhoneNumber": $phone_number, "ReportedCallerId": $reported_caller_id, "ReportedCallerName": $reported_caller_name, "Reporter": $reporter, "UnwantedCall": $unwanted_call} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Reputation: Premium service which returns a reputation informaiton of a phone number via API.
#
# GET /api/2015-11-01/Reputation/{phoneNumber}
# operationId: Reputation_Reputation
export def "2015-11-01-reputation get" [
  phone_number: string
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
]: nothing -> record<CallType: string, Confidence: int, IsSpam: bool, LastComplaintDate: string, ReportedCallerName: string, Tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($phone_number | is-empty) { error make --unspanned { msg: "path parameter 'phoneNumber' must be non-empty" } }
  let full_url = (build-url $base ({phone_number: (encode-path-segment $phone_number)} | format pattern "/api/2015-11-01/Reputation/{phone_number}") $auth.query)
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
