# Auto-generated client for GoToWebinar v1.0.0
# Source: https://api.apis.guru/v2/specs/getgo.com/gotowebinar/1.0.0/swagger.json
# Auth: --token flag or $env.GOTOWEBINAR_TOKEN

const BASE_URL = "https://api.getgo.com/G2W/rest"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GOTOWEBINAR_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://api.getgo.com/G2W/rest"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def locale-completer [] { ["de_DE" "en_US" "es_ES" "fr_FR" "it_IT" "zh_CN"] }
def type-completer [] { ["Hybrid" "PSTN" "Private" "VOIP"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts-webinars get-list" } } | get name | first)
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

# Get all webinars for an account
#
# GET /accounts/{accountKey}/webinars
# operationId: getAllAccountWebinars
export def "accounts-webinars get-list" [
  account_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-time: string # A required start of datetime range in ISO8601 UTC format, e.g. 2015-07-13T10:00:00Z (format: date-time)
  --to-time: string # A required end of datetime range in ISO8601 UTC format, e.g. 2015-07-13T22:00:00Z (format: date-time)
  --page: int # The page number to be displayed. The first page is 0. (format: int64)
  --size: int # The size of the page. (format: int64)
  --authorization: string # Access token
]: nothing -> record<_embedded: record<webinars: list<record>>, page: record<number: int, size: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromTime" $from_time "scalar") (serialize-qp "toTime" $to_time "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_key: (encode-path-segment $account_key)} | format pattern "/accounts/{account_key}/webinars") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get historical webinars
#
# GET /organizers/{organizerKey}/historicalWebinars
# operationId: getHistoricalWebinars
export def "organizers-historical-webinars get" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-time: string # A required start of datetime range in ISO8601 UTC format, e.g. 2015-07-13T10:00:00Z (format: date-time)
  --to-time: string # A required end of datetime range in ISO8601 UTC format, e.g. 2015-07-13T22:00:00Z (format: date-time)
  --authorization: string # Access token
]: nothing -> table<description: string, organizerKey: int, subject: string, timeZone: string, times: list<record>, webinarID: string, webinarKey: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromTime" $from_time "scalar") (serialize-qp "toTime" $to_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}/historicalWebinars") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get organizer sessions
#
# GET /organizers/{organizerKey}/sessions
# operationId: getOrganizerSessions
export def "organizers-sessions get" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-time: string # A required start of datetime range in ISO8601 UTC format, e.g. 2015-07-13T10:00:00Z (format: date-time)
  --to-time: string # A required end of datetime range in ISO8601 UTC format, e.g. 2015-07-13T22:00:00Z (format: date-time)
  --authorization: string # Access token
]: nothing -> table<endTime: string, registrantsAttended: int, sessionKey: int, startTime: string, webinarID: string, webinarKey: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromTime" $from_time "scalar") (serialize-qp "toTime" $to_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}/sessions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get upcoming webinars
#
# GET /organizers/{organizerKey}/upcomingWebinars
# operationId: getUpcomingWebinars
export def "organizers-upcoming-webinars get" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<description: string, inSession: bool, organizerKey: int, registrationUrl: string, subject: string, timeZone: string, times: list<record>, webinarID: string, webinarKey: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}/upcomingWebinars"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all webinars
#
# GET /organizers/{organizerKey}/webinars
# operationId: getAllWebinars
export def "organizers-webinars get-list" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<description: string, inSession: bool, numberOfRegistrants: int, organizerKey: int, registrationUrl: string, subject: string, timeZone: string, times: list<record>, webinarID: string, webinarKey: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}/webinars"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create webinar
#
# POST /organizers/{organizerKey}/webinars
# operationId: createWebinar
# --times item shape: {endTime: string, startTime: string}
export def "organizers-webinars create" [
  organizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
  --description: string # A short description of the webinar (2048 characters maximum)
  --is-password-protected: oneof<nothing, bool> # A boolean flag indicating if the webinar is password protected or not. (default: false)
  subject: string # The name/subject of the webinar (128 characters maximum)
  --time-zone: string # The time zone where the webinar is taking place (must be a valid time zone ID, see https://goto-developer.logmein.com/time-zones). If this parameter is not passed, the timezone of the organizer's profile will be used
  times: list # Array with startTime and endTime for webinar. Since this call creates single session webinars, the array can only contain a single pair of startTime and endTime — item shape: {endTime: string, startTime: string}
  --type: string # Specifies the webinar type. The default type value is "single_session", which is used to create a single webinar session. The possible values are "single_session", "series", "sequence". If type is set to "single_session", a single webinar session is created. If type is set to "series", a webinar series is created. In this case 2 or more timeframes must be specified for each webinar. Example: "times": [{"startTime": "...", "endTime": "..."},{"startTime": "...", "endTime": "..."},{"startTime": "...", "endTime": "..."}. If type is set to "sequence" a sequence of webinars is created. The times object in the body must be replaced by the "recurrenceStart" object. Example: "recurrenceStart": {"startTime":"2012-06-12T16:00:00Z", "endTime": "2012-06-12T17:00:00Z" }. The "recurrenceEnd" and "recurrencePattern" body parameter must be specified. Example: , "recurrenceEnd": "2012-07-10", "recurrencePattern": "daily". (default: single_session)
]: any -> record<webinarKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key)} | format pattern "/organizers/{organizer_key}/webinars"))
  let req_body = {"description": $description, "isPasswordProtected": $is_password_protected, "subject": $subject, "timeZone": $time_zone, "times": $times, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Cancel webinar
#
# DELETE /organizers/{organizerKey}/webinars/{webinarKey}
# operationId: cancelWebinar
export def "organizers-webinars cancel" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --send-cancellation-emails: oneof<nothing, bool> # Indicates whether cancellation notice emails should be sent. The default value is false
  --authorization: string # Access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sendCancellationEmails" $send_cancellation_emails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webinar
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}
# operationId: getWebinar
export def "organizers-webinars get" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> record<description: string, inSession: bool, numberOfOpenedInvitations: int, numberOfRegistrants: int, numberOfRegistrationLinkClicks: int, organizerKey: int, registrationUrl: string, subject: string, timeZone: string, times: table<endTime: string, startTime: string>, webinarID: string, webinarKey: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update webinar
#
# PUT /organizers/{organizerKey}/webinars/{webinarKey}
# operationId: updateWebinar
# --times item shape: {endTime: string, startTime: string}
export def "organizers-webinars update" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify-participants: oneof<nothing, bool> # Defines whether to send notifications to participants
  --authorization: string # Access token
  --description: string # A description of the webinar (2048 characters maximum)
  --locale: string@locale-completer # The webinar language
  --subject: string # The name/subject of the webinar (128 characters maximum)
  --time-zone: string # The time zone where the webinar is taking place (must be a valid time zone ID, see https://goto-developer.logmein.com/time-zones). If this parameter is not passed, the timezone of the organizer's profile will be used
  --times: list # Array with start and end time(s) for webinar — item shape: {endTime: string, startTime: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notifyParticipants" $notify_participants "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}") $qp)
  let req_body = {"description": $description, "locale": $locale, "subject": $subject, "timeZone": $time_zone, "times": $times} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get attendees for all webinar sessions
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/attendees
# operationId: getAttendeesForAllWebinarSessions
export def "organizers-webinars-attendees get-for-list-sessions" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<attendance: list<record>, attendanceTimeInSeconds: int, email: string, firstName: string, lastName: string, registrantKey: int, sessionKey: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/attendees"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get audio information
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/audio
# operationId: getAudioInformation
export def "organizers-webinars-audio get-information" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> record<confCallNumbers: record, privateInfo: record<attendee: string, organizer: string, panelist: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/audio"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update audio information
#
# POST /organizers/{organizerKey}/webinars/{webinarKey}/audio
# operationId: updateAudioInformation
# --privateInfo shape: {attendee: string, organizer?: string, panelist?: string}
# --pstnInfo shape: {tollCountries?: list<string>, tollFreeCountries?: list<string>}
export def "organizers-webinars-audio update-information" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify-participants: oneof<nothing, bool> # Defines whether to send notifications to participants
  --authorization: string # Access token
  --private-info: any # Defines the audio data for an own conferencing system — shape: {attendee: string, organizer?: string, panelist?: string}
  --pstn-info: any # Defines the audio/conferencing settings for the specified webinar. It required to pass 'tollFreeCountries' or 'tollCountries' or both. — shape: {tollCountries?: list<string>, tollFreeCountries?: list<string>}
  type: string@type-completer # How to connect to the webinar's audio conference
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notifyParticipants" $notify_participants "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/audio") $qp)
  let req_body = {"privateInfo": $private_info, "pstnInfo": $pstn_info, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get co-organizers
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/coorganizers
# operationId: getCoorganizers
export def "organizers-webinars-coorganizers get" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<email: string, external: bool, givenName: string, joinLink: string, memberKey: string, surname: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/coorganizers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create co-organizers
#
# POST /organizers/{organizerKey}/webinars/{webinarKey}/coorganizers
# operationId: createCoorganizers
export def "organizers-webinars-coorganizers create" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
  --body: record
]: any -> table<email: string, external: bool, givenName: string, joinLink: string, memberKey: string, surname: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/coorganizers"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete co-organizer
#
# DELETE /organizers/{organizerKey}/webinars/{webinarKey}/coorganizers/{coorganizerKey}
# operationId: deleteCoorganizer
export def "organizers-webinars-coorganizers delete" [
  organizer_key: int
  webinar_key: int
  coorganizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --external: oneof<nothing, bool> # By default only internal co-organizers (with a GoToWebinar account) can be deleted. If you want to use this call for external co-organizers you have to set this parameter to 'true'.
  --authorization: string # Access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "external" $external "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key), coorganizer_key: (encode-path-segment $coorganizer_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/coorganizers/{coorganizer_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resend invitation
#
# POST /organizers/{organizerKey}/webinars/{webinarKey}/coorganizers/{coorganizerKey}/resendInvitation
# operationId: resendCoorganizerInvitation
export def "organizers-webinars-coorganizers-resend-invitation resend" [
  organizer_key: int
  webinar_key: int
  coorganizer_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --external: oneof<nothing, bool> # By default only internal co-organizers (with a GoToWebinar account) will retrieve the resent invitation email. If you want to use this call for external co-organizers you have to set this parameter to 'true'.
  --authorization: string # Access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "external" $external "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key), coorganizer_key: (encode-path-segment $coorganizer_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/coorganizers/{coorganizer_key}/resendInvitation") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webinar meeting times
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/meetingtimes
# operationId: getWebinarMeetingTimes
export def "organizers-webinars-meetingtimes get-meeting-times" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<endTime: string, startTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/meetingtimes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webinar panelists
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/panelists
# operationId: getPanelists
export def "organizers-webinars-panelists get" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<email: string, firstName: string, joinLink: string, lastName: string, name: string, panelistId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/panelists"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Panelists
#
# POST /organizers/{organizerKey}/webinars/{webinarKey}/panelists
# operationId: createPanelists
export def "organizers-webinars-panelists create" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
  --body: record
]: any -> table<email: string, joinLink: string, name: string, panelistKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/panelists"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete webinar panelist
#
# DELETE /organizers/{organizerKey}/webinars/{webinarKey}/panelists/{panelistKey}
# operationId: deleteWebinarPanelist
export def "organizers-webinars-panelists delete" [
  organizer_key: int
  webinar_key: int
  panelist_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key), panelist_key: (encode-path-segment $panelist_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/panelists/{panelist_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resend panelist invitation
#
# POST /organizers/{organizerKey}/webinars/{webinarKey}/panelists/{panelistKey}/resendInvitation
# operationId: resendPanelistInvitation
export def "organizers-webinars-panelists-resend-invitation resend" [
  organizer_key: int
  webinar_key: int
  panelist_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key), panelist_key: (encode-path-segment $panelist_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/panelists/{panelist_key}/resendInvitation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get performance for all webinar sessions
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/performance
# operationId: getPerformanceForAllWebinarSessions
export def "organizers-webinars-performance get-for-list-sessions" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/performance"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get registrants
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/registrants
# operationId: getAllRegistrantsForWebinar
export def "organizers-webinars-registrants get-list" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<email: string, firstName: string, joinUrl: string, lastName: string, registrantKey: int, registrationDate: string, status: string, timeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/registrants"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create registrant
#
# POST /organizers/{organizerKey}/webinars/{webinarKey}/registrants
# operationId: createRegistrant
# --responses item shape: {answerKey?: int, questionKey: int, responseText?: string}
export def "organizers-webinars-registrants create" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resend-confirmation: oneof<nothing, bool> # Indicates whether the confirmation email should be resent when a registrant is re-registered. The default value is false.
  --authorization: string # Access token
  --hdr-accept: string # Set to 'application/vnd.citrix.g2wapi-v1.1+json' to make a registration using fields (custom or default) additional to the basic ones.
  --address: string # The registrant's address
  --city: string # The registrant's city
  --country: string # The registrant's country
  email: string # The registrant's email address
  first_name: string # The registrant's first name
  --industry: string # The type of industry the registrant's organization belongs to
  --job-title: string # The registrant's job title
  last_name: string # The registrant's last name
  --number-of-employees: string # The size in employees of the registrant's organization
  --organization: string # The registrant's organization
  --phone: string # The registrant's phone
  --purchasing-role: string # The registrant's role in purchasing the product
  --purchasing-time-frame: string # The time frame within which the product will be purchased
  --questions-and-comments: string # Any questions or comments the registrant made at the time of registration
  --responses: list # Set the answers of all questions — item shape: {answerKey?: int, questionKey: int, responseText?: string}
  --body-source: string # The source that led to the registration. This can be any string like 'Newsletter 123' or 'Marketing campaign ABC'
  --state: string # The registrant's state (US only)
  --zip-code: string # The registrant's zip (post) code
]: any -> record<joinUrl: string, registrantKey: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resendConfirmation" $resend_confirmation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/registrants") $qp)
  let req_body = {"address": $address, "city": $city, "country": $country, "email": $email, "firstName": $first_name, "industry": $industry, "jobTitle": $job_title, "lastName": $last_name, "numberOfEmployees": $number_of_employees, "organization": $organization, "phone": $phone, "purchasingRole": $purchasing_role, "purchasingTimeFrame": $purchasing_time_frame, "questionsAndComments": $questions_and_comments, "responses": $responses, "source": $body_source, "state": $state, "zipCode": $zip_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get registration fields
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/registrants/fields
# operationId: getRegistrationFields
export def "organizers-webinars-registrants-fields get-registration" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> record<fields: table<answers: list, field: string, maxSize: int, required: bool>, questions: table<answers: list, maxSize: int, question: string, questionKey: int, required: bool, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/registrants/fields"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete registrant
#
# DELETE /organizers/{organizerKey}/webinars/{webinarKey}/registrants/{registrantKey}
# operationId: deleteRegistrant
export def "organizers-webinars-registrants delete" [
  organizer_key: int
  webinar_key: int
  registrant_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key), registrant_key: (encode-path-segment $registrant_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/registrants/{registrant_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get registrant
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/registrants/{registrantKey}
# operationId: getRegistrant
export def "organizers-webinars-registrants get" [
  organizer_key: int
  webinar_key: int
  registrant_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> record<address: string, city: string, country: string, email: string, employeeCount: string, firstName: string, implementationTimeFrame: string, industry: string, jobTitle: string, joinUrl: string, lastName: string, numberOfEmployees: string, organization: string, phone: string, purchasingRole: string, purchasingTimeFrame: string, questionsAndComments: string, registrantKey: int, registrationDate: string, responses: table<answer: string, question: string>, source: string, state: string, status: string, timeZone: string, type: string, unsubscribed: bool, zipCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key), registrant_key: (encode-path-segment $registrant_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/registrants/{registrant_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webinar sessions
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions
# operationId: getAllSessions
export def "organizers-webinars-sessions get-list" [
  organizer_key: int
  webinar_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<endTime: string, registrantsAttended: int, sessionKey: int, startTime: string, webinarID: string, webinarKey: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/sessions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webinar session
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}
# operationId: getWebinarSession
export def "organizers-webinars-sessions get" [
  organizer_key: int
  webinar_key: int
  session_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<attendance: list<record>, attendanceTimeInSeconds: int, email: string, firstName: string, lastName: string, registrantKey: int, sessionKey: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key), session_key: (encode-path-segment $session_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/sessions/{session_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get session attendees
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/attendees
# operationId: getAttendees
export def "organizers-webinars-sessions-attendees list" [
  organizer_key: int
  webinar_key: int
  session_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<attendance: list<record>, attendanceTimeInSeconds: int, email: string, firstName: string, lastName: string, registrantKey: int, sessionKey: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key), session_key: (encode-path-segment $session_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/sessions/{session_key}/attendees"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attendee
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/attendees/{registrantKey}
# operationId: getAttendee
export def "organizers-webinars-sessions-attendees get" [
  organizer_key: int
  webinar_key: int
  session_key: int
  registrant_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> record<email: string, firstName: string, joinUrl: string, lastName: string, registrantKey: int, registrationDate: string, status: string, timeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key), session_key: (encode-path-segment $session_key), registrant_key: (encode-path-segment $registrant_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/sessions/{session_key}/attendees/{registrant_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attendee poll answers
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/attendees/{registrantKey}/polls
# operationId: getAttendeePollAnswers
export def "organizers-webinars-sessions-attendees-polls get-answers" [
  organizer_key: int
  webinar_key: int
  session_key: int
  registrant_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<answer: string, question: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key), session_key: (encode-path-segment $session_key), registrant_key: (encode-path-segment $registrant_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/sessions/{session_key}/attendees/{registrant_key}/polls"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attendee questions
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/attendees/{registrantKey}/questions
# operationId: getAttendeeQuestions
export def "organizers-webinars-sessions-attendees-questions get" [
  organizer_key: int
  webinar_key: int
  session_key: int
  registrant_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<answers: list<record>, askedBy: string, question: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key), session_key: (encode-path-segment $session_key), registrant_key: (encode-path-segment $registrant_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/sessions/{session_key}/attendees/{registrant_key}/questions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attendee survey answers
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/attendees/{registrantKey}/surveys
# operationId: getAttendeeSurveyAnswers
export def "organizers-webinars-sessions-attendees-surveys get-answers" [
  organizer_key: int
  webinar_key: int
  session_key: int
  registrant_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<answer: string, question: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key), session_key: (encode-path-segment $session_key), registrant_key: (encode-path-segment $registrant_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/sessions/{session_key}/attendees/{registrant_key}/surveys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get session performance
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/performance
# operationId: getPerformance
export def "organizers-webinars-sessions-performance get" [
  organizer_key: int
  webinar_key: int
  session_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> record<attendance: record<averageAttendanceTimeSeconds: float, averageAttentiveness: float, averageInterestRating: float, percentageAttendance: float, registrantCount: int>, pollsAndSurveys: record<percentagePollsCompleted: float, percentageSurveysCompleted: float, pollCount: int, questionsAsked: int, surveyCount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key), session_key: (encode-path-segment $session_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/sessions/{session_key}/performance"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get session polls
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/polls
# operationId: getPolls
export def "organizers-webinars-sessions-polls get" [
  organizer_key: int
  webinar_key: int
  session_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<numberOfResponses: int, question: string, responses: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key), session_key: (encode-path-segment $session_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/sessions/{session_key}/polls"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get session questions
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/questions
# operationId: getQuestions
export def "organizers-webinars-sessions-questions get" [
  organizer_key: int
  webinar_key: int
  session_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<answers: list<record>, askedBy: string, question: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key), session_key: (encode-path-segment $session_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/sessions/{session_key}/questions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get session surveys
#
# GET /organizers/{organizerKey}/webinars/{webinarKey}/sessions/{sessionKey}/surveys
# operationId: getSurveys
export def "organizers-webinars-sessions-surveys get" [
  organizer_key: int
  webinar_key: int
  session_key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token
]: nothing -> table<numberOfResponses: int, question: string, responses: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organizer_key: (encode-path-segment $organizer_key), webinar_key: (encode-path-segment $webinar_key), session_key: (encode-path-segment $session_key)} | format pattern "/organizers/{organizer_key}/webinars/{webinar_key}/sessions/{session_key}/surveys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
