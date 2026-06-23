# Auto-generated client for CallFire API Documentation vV2
# Source: https://api.apis.guru/v2/specs/callfire.com/V2/openapi.json
# Auth: --token flag or $env.CALLFIRE_API_DOCUMENTATION_TOKEN

const BASE_URL = "https://api.callfire.com/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CALLFIRE_API_DOCUMENTATION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
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

def base-url-completer [] { ["https://api.callfire.com/v2"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def default-voice-completer [] { ["FEMALE1" "FEMALE2" "FRENCHCANADIAN1" "MALE1" "SPANISH1"] }
def answering-machine-config-completer [] { ["AM_AND_LIVE" "AM_ONLY" "LIVE_IMMEDIATE" "LIVE_WITH_AMD"] }
def status-completer [] { ["ACTIVE" "ERRORS" "NEW" "SOURCE_ERROR" "VALIDATING"] }
def voice-completer [] { ["FEMALE1" "FEMALE2" "FRENCHCANADIAN1" "MALE1" "SPANISH1"] }
def status-completer-1 [] { ["ACTIVE" "PENDING" "RELEASED" "UNAVAILABLE"] }
def type-completer [] { ["EXTRA" "PLAN"] }
def accept-completer [] { ["audio/m4a" "audio/mp3" "audio/wav" "image/gif" "image/jpeg" "image/png" "image/x-bmp" "video/3gpp" "video/mp4"] }
def config-type-completer [] { ["IVR" "TRACKING"] }
def call-feature-status-completer [] { ["DISABLED" "ENABLED" "PENDING" "UNSUPPORTED"] }
def text-feature-status-completer [] { ["DISABLED" "ENABLED" "PENDING" "UNSUPPORTED"] }
def delivery-category-completer [] { ["BOUNCED" "DELIVERED" "NO_CREDITS" "NO_DATA" "OPTED_OUT"] }
def delivery-state-completer [] { ["BUFFERED" "CARRIER_REJECTED" "DELIVERED" "DUPE" "FORWARDED" "GATEWAY_REJECTED" "NOT_DELIVERED" "NOT_GIVEN" "ORIGINAL" "ORIGINATED" "QUEUED" "QUEUED_TRANSCODE" "RATE_LIMIT_EXCEEDED" "REQUEUED_RATE_LIMITED" "REQUEUED_RECOVERABLE_ERROR" "RETRY_MMS_AS_SMS" "SEND_MMS_AS_SMS" "SEND_WITH_ADDITIONAL_SPID" "SERVICE_UNAVAILABLE" "SPAM_DETECTED" "SUBMITTED" "TRUNCATED" "UNKNOWN" "UNSENT_ALREADY_SCRUBBED" "UNSENT_BAD_DATA" "UNSENT_DAILY_LIMIT_REACHED" "UNSENT_FORCE_STOPPED" "UNSENT_FREE_TRIAL" "UNSENT_INTERNATIONAL" "UNSENT_INVALID_NUMBER" "UNSENT_INVALID_TIMEZONE_OR_DNC" "UNSENT_MESSAGE_BLOCKED" "UNSENT_MESSAGE_TOO_LONG" "UNSENT_NO_CREDITS" "UNSENT_NO_GATEWAY" "UNSENT_NO_WIRELESS_CARRIER" "UNSENT_OPTED_OUT_GLOBAL" "UNSENT_OPTED_OUT_LOCAL" "UNSENT_PERIOD_LIMIT" "UNSENT_QUEUE_LIMIT_REACHED" "UNSENT_SCHEDULER_CAPACITY_EXCEEDED" "UNSENT_SYSTEM_ERROR" "UNSENT_TIME_LIMIT_REACHED" "UNSENT_TOKEN_LIMIT_REACHED"] }
def big-message-strategy-completer [] { ["DO_NOT_SEND" "MMS" "SEND_MULTIPLE" "TRIM"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "calls find" } } | get name | first)
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

# Find calls
#
# GET /calls
# operationId: findCalls
export def "calls find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --id: list<int> # Lists the Call ids to search for. If calls ids are specified then other query parameters can be ignored
  --campaign-id: int # An id of a campaign, queries for calls included to a particular campaign. Specify null for all campaigns and 0 for default campaign (format: int64)
  --batch-id: int # An id of a contact batch, queries for calls of a particular contact batch (format: int64)
  --from-number: string # Phone number in E.164 format (11-digit) that call was from. Example: 12132000384
  --to-number: string # Phone number in E.164 format (11-digit) that call was sent to. Example: 12132000384
  --label: string # A label for a specific call
  --states: string # Searches for all calls which correspond to statuses listed in a comma separated string. Available values: READY, SELECTED, CALLBACK, FINISHED, DISABLED, DNC, DUP, INVALID, TIMEOUT, PERIOD_LIMIT. See [call states and results](https://developers.callfire.com/results-responses-errors.html)
  --results: string # Searches for all calls with statuses listed in a comma separated string. Available values: SENT, RECEIVED, DNT, TOO_BIG, INTERNAL_ERROR, CARRIER_ERROR, CARRIER_TEMP_ERROR, UNDIALED. See [call states and results](https://developers.callfire.com/results-responses-errors.html)
  --inbound: oneof<nothing, bool> # Filters inbound calls for "true" value and outbound calls for "false" value
  --interval-begin: int # Start of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
  --interval-end: int # End of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
]: nothing -> record<items: table<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list, modified: int, notes: list, records: list, state: string, toNumber: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "id" $id "multi") (serialize-qp "campaignId" $campaign_id "scalar") (serialize-qp "batchId" $batch_id "scalar") (serialize-qp "fromNumber" $from_number "scalar") (serialize-qp "toNumber" $to_number "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "states" $states "scalar") (serialize-qp "results" $results "scalar") (serialize-qp "inbound" $inbound "scalar") (serialize-qp "intervalBegin" $interval_begin "scalar") (serialize-qp "intervalEnd" $interval_end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/calls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "limit": $limit, "offset": $offset, "id": $id, "campaignId": $campaign_id, "batchId": $batch_id, "fromNumber": $from_number, "toNumber": $to_number, "label": $label, "states": $states, "results": $results, "inbound": $inbound, "intervalBegin": $interval_begin, "intervalEnd": $interval_end} | compact), body: null}
}

# Send calls
#
# POST /calls
# operationId: sendCalls
export def "calls send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --campaign-id: int # Specifies a campaignId to send calls quickly on a previously created campaign (format: int64)
  --default-live-message: string # Text to be turned into a sound, this text will be played when the phone is answered. Parameter can be overridden for any particular CallRecipient
  --default-machine-message: string # Text to be turned into a sound, this text will be played when answering machine is detected. Parameter can be overridden for any particular CallRecipient
  --default-live-message-sound-id: int # Id of sound file to play if phone is answered. Parameter can be overridden for any particular CallRecipient (format: int64)
  --default-machine-message-sound-id: int # An id of a sound file to play if answering machine is detected. Parameter can be overridden for any particular CallRecipient (format: int64)
  --default-voice: string@default-voice-completer # The voice set by default for all text-to-speech messages defined in CallRecipient objects or as default *Message properties
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --body: list
]: any -> record<items: table<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list, modified: int, notes: list, records: list, state: string, toNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "campaignId" $campaign_id "scalar") (serialize-qp "defaultLiveMessage" $default_live_message "scalar") (serialize-qp "defaultMachineMessage" $default_machine_message "scalar") (serialize-qp "defaultLiveMessageSoundId" $default_live_message_sound_id "scalar") (serialize-qp "defaultMachineMessageSoundId" $default_machine_message_sound_id "scalar") (serialize-qp "defaultVoice" $default_voice "scalar") (serialize-qp "strictValidation" $strict_validation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/calls" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"fields": $fields, "campaignId": $campaign_id, "defaultLiveMessage": $default_live_message, "defaultMachineMessage": $default_machine_message, "defaultLiveMessageSoundId": $default_live_message_sound_id, "defaultMachineMessageSoundId": $default_machine_message_sound_id, "defaultVoice": $default_voice, "strictValidation": $strict_validation} | compact), body: $req_body}
}

# Find call broadcasts
#
# GET /calls/broadcasts
# operationId: findCallBroadcasts
export def "calls-broadcasts find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 10)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --label: string # A label of a voice broadcast
  --name: string # A name of voice broadcast
  --running: oneof<nothing, bool> # Specify whether the campaigns should be running or not
  --scheduled: oneof<nothing, bool> # Specify whether the campaigns should be scheduled or not
  --interval-begin: int # Start of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
  --interval-end: int # End of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
]: nothing -> record<items: table<answeringMachineConfig: string, dialplanXml: string, fromNumber: string, id: int, labels: list, lastModified: int, localTimeRestriction: record, maxActive: int, maxActiveTransfers: int, name: string, recipients: list, resumeNextDay: bool, retryConfig: record, schedules: list, sounds: record, status: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "running" $running "scalar") (serialize-qp "scheduled" $scheduled "scalar") (serialize-qp "intervalBegin" $interval_begin "scalar") (serialize-qp "intervalEnd" $interval_end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/calls/broadcasts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "limit": $limit, "offset": $offset, "label": $label, "name": $name, "running": $running, "scheduled": $scheduled, "intervalBegin": $interval_begin, "intervalEnd": $interval_end} | compact), body: null}
}

# Create a call broadcast
#
# POST /calls/broadcasts
# operationId: createCallBroadcast
# --localTimeRestriction shape: {beginHour?: int, beginMinute?: int, enabled?: bool, endHour?: int, endMinute?: int}
# --recipients item shape: {attributes?: record, contactId?: int, fromNumber?: string, phoneNumber?: string}
# --retryConfig shape: {maxAttempts?: int, minutesBetweenAttempts?: int, retryPhoneTypes?: list<string>, retryResults?: list<string>}
# --schedules item shape: {campaignId?: int, daysOfWeek?: list<string>, id?: int, startDate?: record, startTimeOfDay?: record, stopDate?: record, stopTimeOfDay?: record, timeZone?: string}
# --sounds shape: {dncDigit?: string, dncSoundId?: int, dncSoundText?: string, dncSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", liveSoundId?: int, liveSoundText?: string, liveSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", machineSoundId?: int, machineSoundText?: string, machineSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", transferDigit?: string, transferNumber?: string, transferSoundId?: int, transferSoundText?: string, ... (1 more fields)}
export def "calls-broadcasts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: oneof<nothing, bool> # Specify whether to immediately start this campaign (not required)
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --answering-machine-config: string@answering-machine-config-completer # Specifies which action should be taken if answering machine was detected, default value: AM_AND_LIVE. Available values: AM_ONLY - run AMD (Answering Machine Detection), hang up if LA (Live Answer); AM_AND_LIVE - run AMD, play separate live vs. machine sound; LIVE_WITH_AMD, run AMD, hang up if machine answers; LIVE_IMMEDIATE - no AMD, play live sound immediately
  --dialplan-xml: string # IVR xml is a document which describes the dialplan to setup the IVR broadcast
  --from-number: string # Phone number in E.164 format (11-digit) or short code for text. Example: 12132000384, 67076
  --id: int # A unique id of broadcast (readonly) (format: int64)
  --labels: list<string> # Labels of a broadcast
  --local-time-restriction: record # Represents a range of time during which CallFire will send a call or text to recipients. Timeframe uses the local timezone of recipient's number — shape: {beginHour?: int, beginMinute?: int, enabled?: bool, endHour?: int, endMinute?: int}
  --max-active: int # Sets a maximum number of calls to be dialed by CallFire at once (format: int32)
  --max-active-transfers: int # A maximum number of active transfers (format: int32)
  --name: string # A name of a broadcast
  --recipients: list # Recipients of a call broadcast, can be either existing contacts or a new ones — item shape: {attributes?: record, contactId?: int, fromNumber?: string, phoneNumber?: string}
  --resume-next-day: oneof<nothing, bool> # If true resumes the unfinished campaign to the next day
  --retry-config: record # Retry configuration will help you to resend a call or text if it was not delivered first time — shape: {maxAttempts?: int, minutesBetweenAttempts?: int, retryPhoneTypes?: list<string>, retryResults?: list<string>}
  --schedules: list # A list of schedule objects which specifies a range of time when broadcast should be started and stopped. Supports the scheduling per day of week — item shape: {campaignId?: int, daysOfWeek?: list<string>, id?: int, startDate?: record, startTimeOfDay?: record, stopDate?: record, stopTimeOfDay?: record, timeZone?: string}
  --sounds: record # A set of sounds assigned to a voice broadcast to play according to an answering machine configuration. You can add the existing sounds from the account's sound library or to provide a text which will be converted into a speech. There are four sound options available for a Voice Broadcast campaign — shape: {dncDigit?: string, dncSoundId?: int, dncSoundText?: string, dncSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", liveSoundId?: int, liveSoundText?: string, liveSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", machineSoundId?: int, machineSoundText?: string, machineSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", transferDigit?: string, transferNumber?: string, transferSoundId?: int, transferSoundText?: string, ... (1 more fields)}
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "strictValidation" $strict_validation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/calls/broadcasts" $qp)
  let req_body = {"answeringMachineConfig": $answering_machine_config, "dialplanXml": $dialplan_xml, "fromNumber": $from_number, "id": $id, "labels": $labels, "localTimeRestriction": $local_time_restriction, "maxActive": $max_active, "maxActiveTransfers": $max_active_transfers, "name": $name, "recipients": $recipients, "resumeNextDay": $resume_next_day, "retryConfig": $retry_config, "schedules": $schedules, "sounds": $sounds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"start": $start, "strictValidation": $strict_validation} | compact), body: $req_body}
}

# Find a specific call broadcast
#
# GET /calls/broadcasts/{id}
# operationId: getCallBroadcast
export def "calls-broadcasts get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<answeringMachineConfig: string, dialplanXml: string, fromNumber: string, id: int, labels: list<string>, lastModified: int, localTimeRestriction: record<beginHour: int, beginMinute: int, enabled: bool, endHour: int, endMinute: int>, maxActive: int, maxActiveTransfers: int, name: string, recipients: table<attributes: record, contactId: int, fromNumber: string, phoneNumber: string>, resumeNextDay: bool, retryConfig: record<maxAttempts: int, minutesBetweenAttempts: int, retryPhoneTypes: list<string>, retryResults: list<string>>, schedules: table<campaignId: int, daysOfWeek: list, id: int, startDate: record, startTimeOfDay: record, stopDate: record, stopTimeOfDay: record, timeZone: string>, sounds: record<dncDigit: string, dncSoundId: int, dncSoundText: string, dncSoundTextVoice: string, liveSoundId: int, liveSoundText: string, liveSoundTextVoice: string, machineSoundId: int, machineSoundText: string, machineSoundTextVoice: string, transferDigit: string, transferNumber: string, transferSoundId: int, transferSoundText: string, transferSoundTextVoice: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calls/broadcasts/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Update a call broadcast
#
# PUT /calls/broadcasts/{id}
# operationId: updateCallBroadcast
# --localTimeRestriction shape: {beginHour?: int, beginMinute?: int, enabled?: bool, endHour?: int, endMinute?: int}
# --recipients item shape: {attributes?: record, contactId?: int, fromNumber?: string, phoneNumber?: string}
# --retryConfig shape: {maxAttempts?: int, minutesBetweenAttempts?: int, retryPhoneTypes?: list<string>, retryResults?: list<string>}
# --schedules item shape: {campaignId?: int, daysOfWeek?: list<string>, id?: int, startDate?: record, startTimeOfDay?: record, stopDate?: record, stopTimeOfDay?: record, timeZone?: string}
# --sounds shape: {dncDigit?: string, dncSoundId?: int, dncSoundText?: string, dncSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", liveSoundId?: int, liveSoundText?: string, liveSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", machineSoundId?: int, machineSoundText?: string, machineSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", transferDigit?: string, transferNumber?: string, transferSoundId?: int, transferSoundText?: string, ... (1 more fields)}
export def "calls-broadcasts update" [
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
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --answering-machine-config: string@answering-machine-config-completer # Specifies which action should be taken if answering machine was detected, default value: AM_AND_LIVE. Available values: AM_ONLY - run AMD (Answering Machine Detection), hang up if LA (Live Answer); AM_AND_LIVE - run AMD, play separate live vs. machine sound; LIVE_WITH_AMD, run AMD, hang up if machine answers; LIVE_IMMEDIATE - no AMD, play live sound immediately
  --dialplan-xml: string # IVR xml is a document which describes the dialplan to setup the IVR broadcast
  --from-number: string # Phone number in E.164 format (11-digit) or short code for text. Example: 12132000384, 67076
  --body-id: int # A unique id of broadcast (readonly) (format: int64)
  --labels: list<string> # Labels of a broadcast
  --local-time-restriction: record # Represents a range of time during which CallFire will send a call or text to recipients. Timeframe uses the local timezone of recipient's number — shape: {beginHour?: int, beginMinute?: int, enabled?: bool, endHour?: int, endMinute?: int}
  --max-active: int # Sets a maximum number of calls to be dialed by CallFire at once (format: int32)
  --max-active-transfers: int # A maximum number of active transfers (format: int32)
  --name: string # A name of a broadcast
  --recipients: list # Recipients of a call broadcast, can be either existing contacts or a new ones — item shape: {attributes?: record, contactId?: int, fromNumber?: string, phoneNumber?: string}
  --resume-next-day: oneof<nothing, bool> # If true resumes the unfinished campaign to the next day
  --retry-config: record # Retry configuration will help you to resend a call or text if it was not delivered first time — shape: {maxAttempts?: int, minutesBetweenAttempts?: int, retryPhoneTypes?: list<string>, retryResults?: list<string>}
  --schedules: list # A list of schedule objects which specifies a range of time when broadcast should be started and stopped. Supports the scheduling per day of week — item shape: {campaignId?: int, daysOfWeek?: list<string>, id?: int, startDate?: record, startTimeOfDay?: record, stopDate?: record, stopTimeOfDay?: record, timeZone?: string}
  --sounds: record # A set of sounds assigned to a voice broadcast to play according to an answering machine configuration. You can add the existing sounds from the account's sound library or to provide a text which will be converted into a speech. There are four sound options available for a Voice Broadcast campaign — shape: {dncDigit?: string, dncSoundId?: int, dncSoundText?: string, dncSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", liveSoundId?: int, liveSoundText?: string, liveSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", machineSoundId?: int, machineSoundText?: string, machineSoundTextVoice?: "MALE1"|"FEMALE1"|"FEMALE2"|"SPANISH1"|"FRENCHCANADIAN1", transferDigit?: string, transferNumber?: string, transferSoundId?: int, transferSoundText?: string, ... (1 more fields)}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "strictValidation" $strict_validation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calls/broadcasts/{id}") $qp)
  let req_body = {"answeringMachineConfig": $answering_machine_config, "dialplanXml": $dialplan_xml, "fromNumber": $from_number, "id": $body_id, "labels": $labels, "localTimeRestriction": $local_time_restriction, "maxActive": $max_active, "maxActiveTransfers": $max_active_transfers, "name": $name, "recipients": $recipients, "resumeNextDay": $resume_next_day, "retryConfig": $retry_config, "schedules": $schedules, "sounds": $sounds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"strictValidation": $strict_validation} | compact), body: $req_body}
}

# Archive voice broadcast
#
# POST /calls/broadcasts/{id}/archive
# operationId: archiveVoiceBroadcast
export def "calls-broadcasts-archive archive-voice" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calls/broadcasts/{id}/archive"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find batches in a call broadcast
#
# GET /calls/broadcasts/{id}/batches
# operationId: getCallBroadcastBatches
export def "calls-broadcasts-batches get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
]: nothing -> record<items: table<broadcastId: int, created: int, enabled: bool, id: int, name: string, remaining: int, size: int, status: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calls/broadcasts/{id}/batches") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "limit": $limit, "offset": $offset} | compact), body: null}
}

# Add batches to a call broadcast
#
# POST /calls/broadcasts/{id}/batches
# operationId: addCallBroadcastBatch
# --recipients item shape: {attributes?: record, contactId?: int, fromNumber?: string, phoneNumber?: string}
export def "calls-broadcasts-batches create-batch" [
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
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --contact-list-id: int # An id of existing contact list (format: int64)
  --name: string # A name of batch
  --recipients: list # A list of Recipient objects. For each recipient you can set its phone number or existing contact id to use contact which already exists in account — item shape: {attributes?: record, contactId?: int, fromNumber?: string, phoneNumber?: string}
  --scrub-duplicates: oneof<nothing, bool> # Removes duplicate recipients from batch if true
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "strictValidation" $strict_validation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calls/broadcasts/{id}/batches") $qp)
  let req_body = {"contactListId": $contact_list_id, "name": $name, "recipients": $recipients, "scrubDuplicates": $scrub_duplicates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"strictValidation": $strict_validation} | compact), body: $req_body}
}

# Find calls in a call broadcast
#
# GET /calls/broadcasts/{id}/calls
# operationId: getCallBroadcastCalls
export def "calls-broadcasts-calls get" [
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
  --batch-id: int # An id of a particular batch associated with broadcast (format: int64)
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
]: nothing -> record<items: table<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list, modified: int, notes: list, records: list, state: string, toNumber: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "batchId" $batch_id "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calls/broadcasts/{id}/calls") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"batchId": $batch_id, "fields": $fields, "limit": $limit, "offset": $offset} | compact), body: null}
}

# Add recipients to a call broadcast
#
# POST /calls/broadcasts/{id}/recipients
# operationId: addCallBroadcastRecipients
export def "calls-broadcasts-recipients create" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --body: list
]: any -> record<items: table<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list, modified: int, notes: list, records: list, state: string, toNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "strictValidation" $strict_validation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calls/broadcasts/{id}/recipients") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"fields": $fields, "strictValidation": $strict_validation} | compact), body: $req_body}
}

# Start voice broadcast
#
# POST /calls/broadcasts/{id}/start
# operationId: startVoiceBroadcast
export def "calls-broadcasts-start start-voice" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calls/broadcasts/{id}/start"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get statistics on call broadcast
#
# GET /calls/broadcasts/{id}/stats
# operationId: getCallBroadcastStats
export def "calls-broadcasts-stats get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --begin: int # Start of the search time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
  --end: int # End of the search time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
]: nothing -> record<answeringMachineCount: int, billedAmount: float, billedDuration: int, busyCount: int, callsAttempted: int, callsAwaitingRedial: int, callsDuration: int, callsLiveAnswer: int, callsPlaced: int, callsRemaining: int, dialedCount: int, doNotCallCount: int, errorCount: int, liveCount: int, miscCount: int, noAnswerCount: int, remainingOutboundCount: int, responseRatePercent: int, totalCount: int, totalOutboundCount: int, transferCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "begin" $begin "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calls/broadcasts/{id}/stats") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "begin": $begin, "end": $end} | compact), body: null}
}

# Stop voice broadcast
#
# POST /calls/broadcasts/{id}/stop
# operationId: stopVoiceBroadcast
export def "calls-broadcasts-stop stop-voice" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calls/broadcasts/{id}/stop"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Disable/enable undialed recipients in broadcast
#
# POST /calls/broadcasts/{id}/toggleRecipientsStatus
# operationId: toggleCallBroadcastRecipientsStatus
export def "calls-broadcasts-toggle-recipients-status create" [
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
  --enable: oneof<nothing, bool> # Flag which indicate what to do with calls (true will enable call in DISABLED status and vice versa) (default: false)
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "enable" $enable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calls/broadcasts/{id}/toggleRecipientsStatus") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"enable": $enable} | compact), body: $req_body}
}

# Get call recording by id
#
# GET /calls/recordings/{id}
# operationId: getCallRecording
export def "calls-recordings get-by-id" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<callId: int, campaignId: int, created: int, hash: string, id: int, lengthInBytes: int, lengthInSeconds: int, mp3Url: string, name: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calls/recordings/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Get call recording in mp3 format
#
# GET /calls/recordings/{id}.mp3
# operationId: getCallRecordingMp3
export def "calls-recordings list" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calls/recordings/{id}.mp3"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find a specific call
#
# GET /calls/{id}
# operationId: getCall
export def "calls get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record<deleted: bool, externalId: string, externalSystem: string, extraPhone1: string, extraPhone2: string, extraPhone3: string, firstName: string, homePhone: string, id: int, lastName: string, mobilePhone: string, properties: record, workPhone: string, zipcode: string>, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list<string>, modified: int, notes: table<created: int, text: string>, records: table<answerTime: int, billedAmount: float, callerName: string, duration: int, finishTime: int, id: int, labels: list, notes: list, originateTime: int, questionResponses: list, recordings: list, result: string, switchId: string, toNumber: string>, state: string, toNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calls/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Get call recordings for a call
#
# GET /calls/{id}/recordings
# operationId: getCallRecordings
export def "calls-recordings get-by-id-1" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<items: table<callId: int, campaignId: int, created: int, hash: string, id: int, lengthInBytes: int, lengthInSeconds: int, mp3Url: string, name: string, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/calls/{id}/recordings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Get call recording by name
#
# GET /calls/{id}/recordings/{name}
# operationId: getCallRecordingByName
export def "calls-recordings get-by-id-name" [
  id: int
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<callId: int, campaignId: int, created: int, hash: string, id: int, lengthInBytes: int, lengthInSeconds: int, mp3Url: string, name: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), name: (encode-path-segment $name)} | format pattern "/calls/{id}/recordings/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Get call mp3 recording by name
#
# GET /calls/{id}/recordings/{name}.mp3
# operationId: getCallRecordingMp3ByName
export def "calls-recordings get-mp3" [
  id: int
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), name: (encode-path-segment $name)} | format pattern "/calls/{id}/recordings/{name}.mp3"))
  let accept_val = "audio/mpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find a specific batch
#
# GET /campaigns/batches/{id}
# operationId: getCampaignBatch
export def "campaigns-batches get-batch" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<broadcastId: int, created: int, enabled: bool, id: int, name: string, remaining: int, size: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/campaigns/batches/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Update a batch
#
# PUT /campaigns/batches/{id}
# operationId: updateCampaignBatch
export def "campaigns-batches update-batch" [
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
  --broadcast-id: int # An id of broadcast which batch belongs to (format: int64)
  --enabled: oneof<nothing, bool> # An enabled batch. If batch is disabled its contacts remain undialed/untexted
  --body-id: int # A id of a batch (format: int64)
  --name: string # A batch name
  --status: string@status-completer # A status of batch (NEW, VALIDATING, ERRORS, SOURCE_ERROR, ACTIVE). NEW - batch is queued for validation; VALIDATING - batch is currently validating; ERRORS - batch is processed, some validation errors occurred; SOURCE_ERROR - if contact source is contact list in CallFire system and it has an error; ACTIVE - batch is processed and ready
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/campaigns/batches/{id}"))
  let req_body = {"broadcastId": $broadcast_id, "enabled": $enabled, "id": $body_id, "name": $name, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Find sounds
#
# GET /campaigns/sounds
# operationId: findCampaignSounds
export def "campaigns-sounds find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --filter: string # value to filter file names again; this value is used to check if the filename contains the filter value.
  --include-archived: oneof<nothing, bool> # Includes ARCHIVED sounds for "true" value
  --include-pending: oneof<nothing, bool> # Includes UPLOAD/RECORDING sounds for "true" value
  --include-scrubbed: oneof<nothing, bool> # Includes SCRUBBED sounds for "true" value
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<items: table<created: int, duplicate: bool, id: int, lengthInSeconds: int, name: string, status: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "includeArchived" $include_archived "scalar") (serialize-qp "includePending" $include_pending "scalar") (serialize-qp "includeScrubbed" $include_scrubbed "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/campaigns/sounds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "includeArchived": $include_archived, "includePending": $include_pending, "includeScrubbed": $include_scrubbed, "fields": $fields} | compact), body: null}
}

# Add sound via call
#
# POST /campaigns/sounds/calls
# operationId: postCallCampaignSound
export def "campaigns-sounds-calls create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --name: string # Name of a sound to create
  --to-number: string # Phone number in E.164 11-digit format to call to record a sound. Example: 12132000384
]: any -> record<created: int, duplicate: bool, id: int, lengthInSeconds: int, name: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/campaigns/sounds/calls" $qp)
  let req_body = {"name": $name, "toNumber": $to_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"fields": $fields} | compact), body: $req_body}
}

# Add sound via file
#
# POST /campaigns/sounds/files
# operationId: postFileCampaignSound
export def "campaigns-sounds-files create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  file: string # A sound file encoded in binary form (format: binary)
  --name: string # Optional name of a sound file, if the name is empty than it will be taken from a file
]: any -> record<created: int, duplicate: bool, id: int, lengthInSeconds: int, name: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/campaigns/sounds/files" $qp)
  let req_body = {"file": $file, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: ({"fields": $fields} | compact), body: $req_body}
}

# Add sound via text-to-speech
#
# POST /campaigns/sounds/tts
# operationId: postTTSCampaignSound
export def "campaigns-sounds-tts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --message: string # A text to be turned into sound
  --voice: string@voice-completer # A voice to be used. Available values: MALE1, FEMALE1 , FEMALE2, SPANISH1, FRENCHCANADIAN1
]: any -> record<created: int, duplicate: bool, id: int, lengthInSeconds: int, name: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/campaigns/sounds/tts" $qp)
  let req_body = {"message": $message, "voice": $voice} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"fields": $fields} | compact), body: $req_body}
}

# Delete a specific sound
#
# DELETE /campaigns/sounds/{id}
# operationId: deleteCampaignSound
export def "campaigns-sounds delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/campaigns/sounds/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find a specific sound
#
# GET /campaigns/sounds/{id}
# operationId: getCampaignSound
export def "campaigns-sounds get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<created: int, duplicate: bool, id: int, lengthInSeconds: int, name: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/campaigns/sounds/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Download a MP3 sound
#
# GET /campaigns/sounds/{id}.mp3
# operationId: getCampaignSoundDataMp3
export def "campaigns-sounds get-data-mp3" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/campaigns/sounds/{id}.mp3"))
  let accept_val = "audio/mpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Download a WAV sound
#
# GET /campaigns/sounds/{id}.wav
# operationId: getCampaignSoundDataWav
export def "campaigns-sounds get-data-wav" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/campaigns/sounds/{id}.wav"))
  let accept_val = "audio/wav"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find contacts
#
# GET /contacts
# operationId: findContacts
export def "contacts find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --id: list<int> # A list of contact IDs. If the id parameter is included, the other query parameters are ignored.
  --number: list<string> # Multiple contact numbers can be specified. If the number parameter is included, the other query parameters are ignored.
  --contact-list-id: int # Filters contacts by a particular contact list (format: int64)
  --property-name: string # Name of a contact property to search by
  --property-value: string # Value of a contact property to search by
]: nothing -> record<items: table<deleted: bool, externalId: string, externalSystem: string, extraPhone1: string, extraPhone2: string, extraPhone3: string, firstName: string, homePhone: string, id: int, lastName: string, mobilePhone: string, properties: record, workPhone: string, zipcode: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "id" $id "multi") (serialize-qp "number" $number "multi") (serialize-qp "contactListId" $contact_list_id "scalar") (serialize-qp "propertyName" $property_name "scalar") (serialize-qp "propertyValue" $property_value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "limit": $limit, "offset": $offset, "id": $id, "number": $number, "contactListId": $contact_list_id, "propertyName": $property_name, "propertyValue": $property_value} | compact), body: null}
}

# Create contacts
#
# POST /contacts
# operationId: createContacts
export def "contacts create" [
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
]: any -> record<items: table<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Find do not contact (dnc) items
#
# GET /contacts/dncs
# operationId: findDoNotContacts
export def "contacts-dncs find-do-not" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --prefix: string # Prefix (1-10 digits) of phone numbers
  --campaign-id: int # A campaign id which was used to send a message to a DNC number (format: int64)
  --qp-source: string # A DNC source name to search for DNCs
  --call: oneof<nothing, bool> # Show only Do-Not-Call numbers
  --text: oneof<nothing, bool> # Show only Do-Not-Text numbers
  --inbound-call: oneof<nothing, bool> # ~
  --inbound-text: oneof<nothing, bool> # ~
  --number: list<string> # ~
]: nothing -> record<items: table<call: bool, campaignId: int, created: int, inboundCall: bool, inboundText: bool, number: string, source: string, text: bool>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "campaignId" $campaign_id "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "call" $call "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "inboundCall" $inbound_call "scalar") (serialize-qp "inboundText" $inbound_text "scalar") (serialize-qp "number" $number "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts/dncs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "limit": $limit, "offset": $offset, "prefix": $prefix, "campaignId": $campaign_id, "source": $qp_source, "call": $call, "text": $text, "inboundCall": $inbound_call, "inboundText": $inbound_text, "number": $number} | compact), body: null}
}

# Add do not contact (dnc) numbers
#
# POST /contacts/dncs
# operationId: addDoNotContacts
export def "contacts-dncs create-do-not" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call: oneof<nothing, bool> # If set to true add all given numbers to Do-Not-Call list. Default value: true
  --inbound-call: oneof<nothing, bool> # ~
  --inbound-text: oneof<nothing, bool> # ~
  --numbers: list<string> # A list of phone numbers in E.164 format (11-digit), example: 12132000384, 14142777322
  --body-source: string # A list of new contact objects which need to be added. Default value: Api V2
  --text: oneof<nothing, bool> # If set to true add all given numbers to Do-Not-Text list. Default value: true
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts/dncs")
  let req_body = {"call": $call, "inboundCall": $inbound_call, "inboundText": $inbound_text, "numbers": $numbers, "source": $body_source, "text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete do not contact (dnc) numbers contained in source.
#
# DELETE /contacts/dncs/sources/{source}
# operationId: deleteDoNotContactsBySource
export def "contacts-dncs-sources delete-do-not" [
  source: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($source | is-empty) { error make --unspanned { msg: "path parameter 'source' must be non-empty" } }
  let full_url = (build-url $base ({source: (encode-path-segment $source)} | format pattern "/contacts/dncs/sources/{source}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find universal do not contacts (udnc) associated with toNumber
#
# GET /contacts/dncs/universals/{toNumber}
# operationId: getUniversalDoNotContacts
export def "contacts-dncs-universals get-do-not" [
  to_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-number: string # An optional destination/source number for DNC, specified in E.164 format (11-digit). Example: 12132000384
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<items: table<fromNumber: string, inboundCall: bool, inboundText: bool, outboundCall: bool, outboundText: bool, toNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($to_number | is-empty) { error make --unspanned { msg: "path parameter 'toNumber' must be non-empty" } }
  let qp = [(serialize-qp "fromNumber" $from_number "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({to_number: (encode-path-segment $to_number)} | format pattern "/contacts/dncs/universals/{to_number}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fromNumber": $from_number, "fields": $fields} | compact), body: null}
}

# Delete do not contact (dnc) number. If number contains commas treat as list of numbers
#
# DELETE /contacts/dncs/{number}
# operationId: deleteDoNotContact
export def "contacts-dncs delete-do-not" [
  number: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($number | is-empty) { error make --unspanned { msg: "path parameter 'number' must be non-empty" } }
  let full_url = (build-url $base ({number: (encode-path-segment $number)} | format pattern "/contacts/dncs/{number}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get do not contact (dnc)
#
# GET /contacts/dncs/{number}
# operationId: getDoNotContact
export def "contacts-dncs get-do-not" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<call: bool, campaignId: int, created: int, inboundCall: bool, inboundText: bool, number: string, source: string, text: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($number | is-empty) { error make --unspanned { msg: "path parameter 'number' must be non-empty" } }
  let full_url = (build-url $base ({number: (encode-path-segment $number)} | format pattern "/contacts/dncs/{number}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an individual do not contact (dnc) number
#
# PUT /contacts/dncs/{number}
# operationId: updateDoNotContact
export def "contacts-dncs update-do-not" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call: oneof<nothing, bool> # A number on Do-Not-Call list
  --inbound-call: oneof<nothing, bool> # ~
  --inbound-text: oneof<nothing, bool> # ~
  --body-number: string # A single DNC number in E.164 format (11-digit). Example: 12132000384
  --body-source: string # The name of DNC source (can be the name of DNC list that user uploads to CallFire)
  --text: oneof<nothing, bool> # A number on Do-Not-Text list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($number | is-empty) { error make --unspanned { msg: "path parameter 'number' must be non-empty" } }
  let full_url = (build-url $base ({number: (encode-path-segment $number)} | format pattern "/contacts/dncs/{number}"))
  let req_body = {"call": $call, "inboundCall": $inbound_call, "inboundText": $inbound_text, "number": $body_number, "source": $body_source, "text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Find contact lists
#
# GET /contacts/lists
# operationId: findContactLists
export def "contacts-lists find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --name: string # A name or a partial name of a contact list
  --exact-match: oneof<nothing, bool> # ~
  --contact-count: int # ~ (format: int32)
  --order-by: string # ~
]: nothing -> record<items: table<created: int, id: int, name: string, size: int, status: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "exactMatch" $exact_match "scalar") (serialize-qp "contactCount" $contact_count "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts/lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "limit": $limit, "offset": $offset, "name": $name, "exactMatch": $exact_match, "contactCount": $contact_count, "orderBy": $order_by} | compact), body: null}
}

# Create contact lists
#
# POST /contacts/lists
# operationId: createContactList
# --contacts item shape: {deleted?: bool, externalId?: string, externalSystem?: string, extraPhone1?: string, extraPhone2?: string, extraPhone3?: string, firstName?: string, homePhone?: string, id?: int, lastName?: string, mobilePhone?: string, properties?: record, workPhone?: string, zipcode?: string}
export def "contacts-lists create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --contact-ids: list<int> # A list of ids of existing contacts in CallFire system
  --contact-numbers: list<string> # List of numbers in E.164 format (11-digit). Example: 12132000384
  --contact-numbers-field: string # A type of a phone number (homePhone, workPhone, mobilePhone). This parameter is used with contactNumbers and specifies which types of phone numbers are included to a contact list
  --contacts: list # A list of new contact objects to be added — item shape: {deleted?: bool, externalId?: string, externalSystem?: string, extraPhone1?: string, extraPhone2?: string, extraPhone3?: string, firstName?: string, homePhone?: string, id?: int, lastName?: string, mobilePhone?: string, properties?: record, workPhone?: string, zipcode?: string}
  --name: string # A name of a contact list
  --use-custom-fields: oneof<nothing, bool> # A flag to indicate how to define property names for contacts. If true, uses the field and property names exactly as defined. If false will assign custom properties and fields to A, B, C, etc
]: any -> record<created: int, id: int, name: string, size: int, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts/lists" $qp)
  let req_body = {"contactIds": $contact_ids, "contactNumbers": $contact_numbers, "contactNumbersField": $contact_numbers_field, "contacts": $contacts, "name": $name, "useCustomFields": $use_custom_fields} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"fields": $fields} | compact), body: $req_body}
}

# Create contact list from file
#
# POST /contacts/lists/upload
# operationId: createContactListFromFile
export def "contacts-lists-upload create-from-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # CSV file to be uploaded (format: binary)
  --name: string # A name of a contact list
  --use-custom-fields: oneof<nothing, bool> # A flag to indicate how to define property names for contacts. If true, uses the field and property names exactly as defined. If false will assign custom properties and fields to A, B, C, etc
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts/lists/upload")
  let req_body = {"file": $file, "name": $name, "useCustomFields": $use_custom_fields} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Delete a contact list
#
# DELETE /contacts/lists/{id}
# operationId: deleteContactList
export def "contacts-lists delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/lists/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find a specific contact list
#
# GET /contacts/lists/{id}
# operationId: getContactList
export def "contacts-lists get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<created: int, id: int, name: string, size: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/lists/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Update a contact list
#
# PUT /contacts/lists/{id}
# operationId: updateContactList
export def "contacts-lists update" [
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
  --name: string # A name of a contact list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/lists/{id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete contacts from a contact list
#
# DELETE /contacts/lists/{id}/items
# operationId: removeContactListItems
export def "contacts-lists-items delete-by-id" [
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
  --contact-id: list<int> # An id of a contact entity in the CallFire system
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "contactId" $contact_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/lists/{id}/items") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"contactId": $contact_id} | compact), body: null}
}

# Find contacts in a contact list
#
# GET /contacts/lists/{id}/items
# operationId: getContactListItems
export def "contacts-lists-items get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32)
]: nothing -> record<items: table<deleted: bool, externalId: string, externalSystem: string, extraPhone1: string, extraPhone2: string, extraPhone3: string, firstName: string, homePhone: string, id: int, lastName: string, mobilePhone: string, properties: record, workPhone: string, zipcode: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/lists/{id}/items") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "limit": $limit, "offset": $offset} | compact), body: null}
}

# Add contacts to a contact list
#
# POST /contacts/lists/{id}/items
# operationId: addContactListItems
# --contacts item shape: {deleted?: bool, externalId?: string, externalSystem?: string, extraPhone1?: string, extraPhone2?: string, extraPhone3?: string, firstName?: string, homePhone?: string, id?: int, lastName?: string, mobilePhone?: string, properties?: record, workPhone?: string, zipcode?: string}
export def "contacts-lists-items create" [
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
  --contact-ids: list<int> # A list of ids of existing contacts in CallFire system
  --contact-numbers: list<string> # A phone number in E.164 format (11-digit). Examples: 12132000384
  --contact-numbers-field: string # A type of phone number (homePhone, workPhone, mobilePhone). This parameter works together with contactNumbers and specifies which types of numbers are included to a list
  --contacts: list # A list of new contact objects which need to be added — item shape: {deleted?: bool, externalId?: string, externalSystem?: string, extraPhone1?: string, extraPhone2?: string, extraPhone3?: string, firstName?: string, homePhone?: string, id?: int, lastName?: string, mobilePhone?: string, properties?: record, workPhone?: string, zipcode?: string}
  --use-custom-fields: oneof<nothing, bool> # A flag to indicate how to define property names for contacts. If true, uses the field and property names exactly as defined. If false will assign custom properties and fields to A, B, C, etc
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/lists/{id}/items"))
  let req_body = {"contactIds": $contact_ids, "contactNumbers": $contact_numbers, "contactNumbersField": $contact_numbers_field, "contacts": $contacts, "useCustomFields": $use_custom_fields} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a contact from a contact list
#
# DELETE /contacts/lists/{id}/items/{contactId}
# operationId: removeContactListItem
export def "contacts-lists-items delete-by-id-contact-id" [
  id: int
  contact_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contactId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), contact_id: (encode-path-segment $contact_id)} | format pattern "/contacts/lists/{id}/items/{contact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a contact
#
# DELETE /contacts/{id}
# operationId: deleteContact
export def "contacts delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find a specific contact
#
# GET /contacts/{id}
# operationId: getContact
export def "contacts get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<deleted: bool, externalId: string, externalSystem: string, extraPhone1: string, extraPhone2: string, extraPhone3: string, firstName: string, homePhone: string, id: int, lastName: string, mobilePhone: string, properties: record, workPhone: string, zipcode: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Update a contact
#
# PUT /contacts/{id}
# operationId: updateContact
export def "contacts update" [
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
  --deleted: oneof<nothing, bool> # A deleted contact, deleted contacts are hidden from search results
  --external-id: string # An external id of a contact for syncing with external sources
  --external-system: string # External system that external id refers to
  --extra-phone1: string # Phone number in E.164 format (11-digit). Example: 12132000384
  --extra-phone2: string # Phone number in E.164 format (11-digit). Example: 12132000384
  --extra-phone3: string # Phone number in E.164 format (11-digit). Example: 12132000384
  --first-name: string # A first name of a contact
  --home-phone: string # Phone number in E.164 format (11-digit). Example: 12132000384
  --body-id: int # An id of a contact (format: int64)
  --last-name: string # A last name of a contact
  --mobile-phone: string # Phone number in E.164 format (11-digit). Example: 12132000384
  --properties: record # Map of user-defined string properties for contact
  --work-phone: string # Phone number in E.164 format (11-digit). Example: 12132000384
  --zipcode: string # A Zip code of a contact
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/{id}"))
  let req_body = {"deleted": $deleted, "externalId": $external_id, "externalSystem": $external_system, "extraPhone1": $extra_phone1, "extraPhone2": $extra_phone2, "extraPhone3": $extra_phone3, "firstName": $first_name, "homePhone": $home_phone, "id": $body_id, "lastName": $last_name, "mobilePhone": $mobile_phone, "properties": $properties, "workPhone": $work_phone, "zipcode": $zipcode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Find a contact's history
#
# GET /contacts/{id}/history
# operationId: getContactHistory
export def "contacts-history get" [
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
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32)
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<calls: table<agentCall: bool, attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalCallResult: string, fromNumber: string, id: int, inbound: bool, labels: list, modified: int, notes: list, records: list, state: string, toNumber: string>, id: int, texts: table<attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list, media: list, message: string, modified: int, records: list, state: string, toNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/{id}/history") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "fields": $fields} | compact), body: null}
}

# Find keywords
#
# GET /keywords
# operationId: findKeywords
export def "keywords find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --keywords: list<string> # A keyword to search for
]: nothing -> record<items: table<keyword: string, number: string, shortCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keywords" $keywords "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/keywords" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"keywords": $keywords} | compact), body: null}
}

# Find keyword leases
#
# GET /keywords/leases
# operationId: findKeywordLeases
export def "keywords-leases find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --filter: string # Filter by part of Keyword name or Label name of Keyword
  --label-name: string # An exact label name to search by
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<items: table<autoRenew: bool, contactListId: int, doubleOptInEnabled: bool, keyword: string, labels: list, leaseBegin: int, leaseEnd: int, number: string, optInConfirmationMessage: string, shortCode: string, status: string, type: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "labelName" $label_name "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/keywords/leases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "labelName": $label_name, "fields": $fields} | compact), body: null}
}

# Find keyword lease configs
#
# GET /keywords/leases/configs
# operationId: findKeywordLeaseConfigs
export def "keywords-leases-configs find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 20)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --filter: string # Filter by part of Keyword name or Label name of Keyword
  --label-name: string # An exact label name to search by
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<items: list<record>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "labelName" $label_name "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/keywords/leases/configs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "labelName": $label_name, "fields": $fields} | compact), body: null}
}

# Find a specific keyword lease config
#
# GET /keywords/leases/configs/{keyword}
# operationId: getKeywordLeaseConfig
export def "keywords-leases-configs get" [
  keyword: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<keyword: string, textInboundConfig: record<forwardEnabled: bool, forwardNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($keyword | is-empty) { error make --unspanned { msg: "path parameter 'keyword' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({keyword: (encode-path-segment $keyword)} | format pattern "/keywords/leases/configs/{keyword}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Update a keyword lease config
#
# PUT /keywords/leases/configs/{keyword}
# operationId: updateKeywordLeaseConfig
# --textInboundConfig shape: {forwardEnabled?: bool, forwardNumber?: string}
export def "keywords-leases-configs update" [
  keyword: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-keyword: string # ~
  --text-inbound-config: record # ~ — shape: {forwardEnabled?: bool, forwardNumber?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($keyword | is-empty) { error make --unspanned { msg: "path parameter 'keyword' must be non-empty" } }
  let full_url = (build-url $base ({keyword: (encode-path-segment $keyword)} | format pattern "/keywords/leases/configs/{keyword}"))
  let req_body = {"keyword": $body_keyword, "textInboundConfig": $text_inbound_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Find a keyword by id
#
# GET /keywords/leases/id/{id}
# operationId: getKeywordLeaseById
export def "keywords-leases-id get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<autoRenew: bool, contactListId: int, doubleOptInEnabled: bool, keyword: string, labels: list<string>, leaseBegin: int, leaseEnd: int, number: string, optInConfirmationMessage: string, shortCode: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/keywords/leases/id/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Find a specific lease
#
# GET /keywords/leases/{keyword}
# operationId: getKeywordLease
export def "keywords-leases get" [
  keyword: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<autoRenew: bool, contactListId: int, doubleOptInEnabled: bool, keyword: string, labels: list<string>, leaseBegin: int, leaseEnd: int, number: string, optInConfirmationMessage: string, shortCode: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($keyword | is-empty) { error make --unspanned { msg: "path parameter 'keyword' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({keyword: (encode-path-segment $keyword)} | format pattern "/keywords/leases/{keyword}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Update a lease
#
# PUT /keywords/leases/{keyword}
# operationId: updateKeywordLease
export def "keywords-leases update" [
  keyword: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-renew: oneof<nothing, bool> # Enables the auto renewal of a keyword lease at the end of each billing cycle
  --contact-list-id: int # Existing contact list ID (format: int64)
  --double-opt-in-enabled: oneof<nothing, bool> # Enable/disable double opt in feature
  --body-keyword: string # A text used as a keyword
  --labels: list<string> # ~
  --lease-begin: int # A time of a lease timestamp, formatted in unix time milliseconds (read only). Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
  --lease-end: int # A date and time when the keyword lease is finishes. Timestamp, formatted in unix time milliseconds (read only). Example: 1473781817000 (format: int64)
  --number: string # A number assigned to keyword. Example: 12132212344
  --opt-in-confirmation-message: string # Opt in confirmation message
  --short-code: string # A short code assigned to keyword. Example: 67076 (Deprecated - please use number instead)
  --status: string@status-completer-1 # A lease status. Available values: PENDING, ACTIVE, RELEASED, UNAVAILABLE
  --type: string@type-completer # ~
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($keyword | is-empty) { error make --unspanned { msg: "path parameter 'keyword' must be non-empty" } }
  let full_url = (build-url $base ({keyword: (encode-path-segment $keyword)} | format pattern "/keywords/leases/{keyword}"))
  let req_body = {"autoRenew": $auto_renew, "contactListId": $contact_list_id, "doubleOptInEnabled": $double_opt_in_enabled, "keyword": $body_keyword, "labels": $labels, "leaseBegin": $lease_begin, "leaseEnd": $lease_end, "number": $number, "optInConfirmationMessage": $opt_in_confirmation_message, "shortCode": $short_code, "status": $status, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Check for a specific keyword
#
# GET /keywords/{keyword}/available
# operationId: isKeywordAvailable
export def "keywords-available get-is" [
  keyword: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<bool, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($keyword | is-empty) { error make --unspanned { msg: "path parameter 'keyword' must be non-empty" } }
  let full_url = (build-url $base ({keyword: (encode-path-segment $keyword)} | format pattern "/keywords/{keyword}/available"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find account details
#
# GET /me/account
# operationId: getAccount
export def "me-account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<active: bool, address: string, age: record<millis: int, standardDays: int, standardHours: int, standardMinutes: int, standardSeconds: int>, agencyManagedAccounts: bool, allowedToCreateCampaign: bool, apiCallLimit: int, archived: bool, autoAddDoNotContact: bool, brand: string, canceled: bool, canceledOrArchived: bool, city: string, companyName: string, country: string, countryOrDefault: string, created: string, dateTimeZone: record<fixed: bool, id: string>, defaultNotificationTtlMillis: int, defaultNumberId: int, ein: string, entityType: string, ez: bool, failedVerificationAttempts: int, fromNumberPool: string, id: int, industry: string, industryName: string, key: string, localTimeZoneRestriction: record<enabled: bool, startTime: string, stopTime: string>, locale: record<country: string, displayCountry: string, displayLanguage: string, displayName: string, displayScript: string, displayVariant: string, extensionKeys: list<string>, iso3Country: string, iso3Language: string, language: string, script: string, unicodeLocaleAttributes: list<string>, unicodeLocaleKeys: list<string>, variant: string>, maxAgents: int, messageClass: string, messageFlows: list<string>, name: string, outboundThreshold: int, receiverPeriodCall: int, receiverPeriodEnabled: bool, receiverPeriodGlobal: int, receiverPeriodText: int, receiverPeriodTimeUnit: string, retainOnlyMetadata: bool, retainOnlyMetadataLastDetailRecordId: int, retainOnlyMetadataLastModified: string, scrub: bool, sharedShortCodeAllowed: bool, sharedShortCodeId: int, soaAccount: any, startCapable: bool, state: string, status: string, textOutboundThreshold: int, timeZone: record<displayName: string, dstsavings: int, id: string, rawOffset: int>, timeZoneId: record<id: string, rules: record<fixedOffset: bool, transitionRules: list, transitions: list>>, trustLevel: string, tsrAgreement: string, tsrInitials: string, uiContext: string, universal: bool, website: string, zipcode: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Find api credentials
#
# GET /me/api/credentials
# operationId: findApiCredentials
export def "me-credentials find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Filter by name
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
]: nothing -> record<items: table<enabled: bool, id: int, name: string, password: string, username: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/api/credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "fields": $fields, "limit": $limit, "offset": $offset} | compact), body: null}
}

# Create api credentials
#
# POST /me/api/credentials
# operationId: createApiCredential
export def "me-credentials create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Is credential enabled
  --id: int # An id of an API credential (format: int64)
  --name: string # A name of an API credential
]: any -> record<enabled: bool, id: int, name: string, password: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/api/credentials")
  let req_body = {"enabled": $enabled, "id": $id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete api credentials
#
# DELETE /me/api/credentials/{id}
# operationId: deleteApiCredential
export def "me-credentials delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/me/api/credentials/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find a specific api credential
#
# GET /me/api/credentials/{id}
# operationId: getApiCredential
export def "me-credentials get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<enabled: bool, id: int, name: string, password: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/me/api/credentials/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Disable specified API credentials
#
# POST /me/api/credentials/{id}/disable
# operationId: disableApiCredentials
export def "me-credentials-disable disable" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/me/api/credentials/{id}/disable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Enable specified API credentials
#
# POST /me/api/credentials/{id}/enable
# operationId: enableApiCredentials
export def "me-credentials-enable enable" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/me/api/credentials/{id}/enable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find credit usage
#
# GET /me/billing/credit-usage
# operationId: getCreditUsage
export def "me-billing-credit-usage get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --interval-begin: int # Beginning of usage period formatted in unix time milliseconds. Example: 1473781817000 (format: int64)
  --interval-end: int # End of usage period formatted in unix time milliseconds. Example: 1473781817000 (format: int64)
]: nothing -> record<callsDurationMinutes: int, creditsUsed: float, intervalBegin: int, intervalEnd: int, textsSent: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "intervalBegin" $interval_begin "scalar") (serialize-qp "intervalEnd" $interval_end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/billing/credit-usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"intervalBegin": $interval_begin, "intervalEnd": $interval_end} | compact), body: null}
}

# Find plan usage
#
# GET /me/billing/plan-usage
# operationId: getBillingPlanUsage
export def "me-billing-plan-usage get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<intervalEnd: int, intervalStart: int, remainingPayAsYouGoCredits: float, remainingPlanCredits: float, totalRemainingCredits: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/billing/plan-usage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find caller ids
#
# GET /me/callerids
# operationId: getCallerIds
export def "me-callerids get-caller" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<items: table<phoneNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/callerids")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a caller id
#
# POST /me/callerids/{callerid}
# operationId: sendVerificationCodeToCallerId
export def "me-callerids send-verification-code-to-caller" [
  callerid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($callerid | is-empty) { error make --unspanned { msg: "path parameter 'callerid' must be non-empty" } }
  let full_url = (build-url $base ({callerid: (encode-path-segment $callerid)} | format pattern "/me/callerids/{callerid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Verify a caller id
#
# POST /me/callerids/{callerid}/verification-code
# operationId: verifyCallerId
export def "me-callerids-verification-code verify-caller" [
  callerid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --verification-code: string # The code used to verify a caller id number
]: any -> oneof<bool, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($callerid | is-empty) { error make --unspanned { msg: "path parameter 'callerid' must be non-empty" } }
  let full_url = (build-url $base ({callerid: (encode-path-segment $callerid)} | format pattern "/me/callerids/{callerid}/verification-code"))
  let req_body = {"verificationCode": $verification_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Find media
#
# GET /media
# operationId: findMedia
export def "media find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --filter: string # value to filter file names again; this value is used to check if the filename contains the filter value.
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<items: table<accountId: int, created: int, id: int, lengthInBytes: int, mediaType: string, name: string, publicUrl: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/media" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "filter": $filter, "fields": $fields} | compact), body: null}
}

# Create media
#
# POST /media
# operationId: createMedia
export def "media create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # Binary media file (format: binary)
  --name: string # A name of a media file
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/media")
  let req_body = {"file": $file, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Download media by extension
#
# GET /media/public/{key}.{extension}
# operationId: getMediaDataByKey
export def "media-public get-data" [
  key: string
  extension: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  if ($extension | is-empty) { error make --unspanned { msg: "path parameter 'extension' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key), extension: (encode-path-segment $extension)} | format pattern "/media/public/{key}.{extension}"))
  let accept_val = ($accept | default "audio/m4a")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific media
#
# GET /media/{id}
# operationId: getMedia
export def "media get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<accountId: int, created: int, id: int, lengthInBytes: int, mediaType: string, name: string, publicUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/media/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Download media by extension
#
# GET /media/{id}.{extension}
# operationId: getMediaData
export def "media get-data" [
  id: int
  extension: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($extension | is-empty) { error make --unspanned { msg: "path parameter 'extension' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), extension: (encode-path-segment $extension)} | format pattern "/media/{id}.{extension}"))
  let accept_val = ($accept | default "audio/m4a")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Download a MP3 media
#
# GET /media/{id}/file
# operationId: getMediaDataBinary
export def "media-file get-data-binary" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/media/{id}/file"))
  let accept_val = "application/binary"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find leases
#
# GET /numbers/leases
# operationId: findNumberLeases
export def "numbers-leases find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --prefix: string # A 4-7 digit prefix
  --city: string # A city name
  --state: string # A two-letter state code. Example: CA, IL, etc.
  --zipcode: string # A five-digit Zipcode
  --label-name: string # A label name
  --toll-free: oneof<nothing, bool> # ~
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<items: table<autoRenew: bool, callFeatureStatus: string, labels: list, leaseBegin: int, leaseEnd: int, nationalFormat: string, number: string, region: record, sendEmailOnCreate: bool, status: string, textFeatureStatus: string, tollFree: bool, type: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "zipcode" $zipcode "scalar") (serialize-qp "labelName" $label_name "scalar") (serialize-qp "tollFree" $toll_free "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/leases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "prefix": $prefix, "city": $city, "state": $state, "zipcode": $zipcode, "labelName": $label_name, "tollFree": $toll_free, "fields": $fields} | compact), body: null}
}

# Find lease configs
#
# GET /numbers/leases/configs
# operationId: findNumberLeaseConfigs
export def "numbers-leases-configs find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --prefix: string # A 4-7 digit prefix
  --city: string # A city name
  --state: string # A two-letter state code. Example: CA, IL, etc.
  --zipcode: string # A five-digit Zipcode
  --label-name: string # A label name
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<items: table<callTrackingConfig: record, configType: string, ivrInboundConfig: record, number: string, textInboundConfig: record>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "zipcode" $zipcode "scalar") (serialize-qp "labelName" $label_name "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/leases/configs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "prefix": $prefix, "city": $city, "state": $state, "zipcode": $zipcode, "labelName": $label_name, "fields": $fields} | compact), body: null}
}

# Find a specific lease config
#
# GET /numbers/leases/configs/{number}
# operationId: getNumberLeaseConfig
export def "numbers-leases-configs get" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<callTrackingConfig: record<failedTransferSoundId: int, googleAnalytics: record<category: string, domain: string, googleAccountId: string>, introSoundId: int, recorded: bool, screen: bool, transferNumbers: list<string>, voicemail: bool, voicemailSoundId: int, weeklySchedule: record<daysOfWeek: list, startTimeOfDay: record, stopTimeOfDay: record, timeZone: string>, whisperSoundId: int>, configType: string, ivrInboundConfig: record<dialplanXml: string>, number: string, textInboundConfig: record<forwardEnabled: bool, forwardNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($number | is-empty) { error make --unspanned { msg: "path parameter 'number' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({number: (encode-path-segment $number)} | format pattern "/numbers/leases/configs/{number}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Update a lease config
#
# PUT /numbers/leases/configs/{number}
# operationId: updateNumberLeaseConfig
# --callTrackingConfig shape: {failedTransferSoundId?: int, googleAnalytics?: record, introSoundId?: int, recorded?: bool, screen?: bool, transferNumbers?: list<string>, voicemail?: bool, voicemailSoundId?: int, weeklySchedule?: record, whisperSoundId?: int}
# --ivrInboundConfig shape: {dialplanXml?: string}
# --textInboundConfig shape: {forwardEnabled?: bool, forwardNumber?: string}
export def "numbers-leases-configs update" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-tracking-config: record # Call tracking configuration allows you track incoming calls, analyze, respond to customers using sms or voice replies. For more information see [call tracking page](https://www.callfire.com/products/call-tracking) — shape: {failedTransferSoundId?: int, googleAnalytics?: record, introSoundId?: int, recorded?: bool, screen?: bool, transferNumbers?: list<string>, voicemail?: bool, voicemailSoundId?: int, weeklySchedule?: record, whisperSoundId?: int}
  --config-type: string@config-type-completer # A type of config. Available values: TRACKING, IVR
  --ivr-inbound-config: record # ~ — shape: {dialplanXml?: string}
  --body-number: string # Phone number in E.164 format (11-digit). Example: 12132000384
  --text-inbound-config: record # ~ — shape: {forwardEnabled?: bool, forwardNumber?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($number | is-empty) { error make --unspanned { msg: "path parameter 'number' must be non-empty" } }
  let full_url = (build-url $base ({number: (encode-path-segment $number)} | format pattern "/numbers/leases/configs/{number}"))
  let req_body = {"callTrackingConfig": $call_tracking_config, "configType": $config_type, "ivrInboundConfig": $ivr_inbound_config, "number": $body_number, "textInboundConfig": $text_inbound_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Find a specific lease
#
# GET /numbers/leases/{number}
# operationId: getNumberLease
export def "numbers-leases get" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<autoRenew: bool, callFeatureStatus: string, labels: list<string>, leaseBegin: int, leaseEnd: int, nationalFormat: string, number: string, region: record<city: string, country: string, latitude: float, longitude: float, prefix: string, state: string, timeZone: string, zipcode: string>, sendEmailOnCreate: bool, status: string, textFeatureStatus: string, tollFree: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($number | is-empty) { error make --unspanned { msg: "path parameter 'number' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({number: (encode-path-segment $number)} | format pattern "/numbers/leases/{number}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Update a lease
#
# PUT /numbers/leases/{number}
# operationId: updateNumberLease
# --region shape: {city?: string, country?: string, latitude?: float, longitude?: float, prefix?: string, state?: string, timeZone?: string, zipcode?: string}
export def "numbers-leases update" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-renew: oneof<nothing, bool> # Enables the auto renewal of number lease at end of each billing cycle
  --call-feature-status: string@call-feature-status-completer # A status of a call feature. Available values: DISABLED, ENABLED
  --labels: list<string> # ~
  --lease-begin: int # A date and time of a lease start. Timestamp, formatted in unix time milliseconds (read only). Example: 1473781817000 (format: int64)
  --lease-end: int # A data and time of a lease finish. Timestamp, formatted in unix time milliseconds (read only). Example: 1473781817000 (format: int64)
  --national-format: string # Formatted number with a country code
  --body-number: string # A phone number in E.164 format (11-digit). Example: 12132000384
  --region: record # Every local number associated with a region. You can query regions to use them in subsequent purchase requests — shape: {city?: string, country?: string, latitude?: float, longitude?: float, prefix?: string, state?: string, timeZone?: string, zipcode?: string}
  --send-email-on-create: oneof<nothing, bool> # ~
  --text-feature-status: string@text-feature-status-completer # A status of a text feature. Available values: DISABLED, ENABLED
  --toll-free: oneof<nothing, bool> # A toll-free number
  --type: string@type-completer # ~
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($number | is-empty) { error make --unspanned { msg: "path parameter 'number' must be non-empty" } }
  let full_url = (build-url $base ({number: (encode-path-segment $number)} | format pattern "/numbers/leases/{number}"))
  let req_body = {"autoRenew": $auto_renew, "callFeatureStatus": $call_feature_status, "labels": $labels, "leaseBegin": $lease_begin, "leaseEnd": $lease_end, "nationalFormat": $national_format, "number": $body_number, "region": $region, "sendEmailOnCreate": $send_email_on_create, "textFeatureStatus": $text_feature_status, "tollFree": $toll_free, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Find local numbers
#
# GET /numbers/local
# operationId: findNumbersLocal
export def "numbers-local find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --prefix: string # A 4-7 digit prefix
  --city: string # A city name
  --state: string # A two-letter state code. Example: CA, IL, etc.
  --zipcode: string # A five-digit Zipcode
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<items: table<nationalFormat: string, number: string, region: record, sendEmailOnCreate: bool, tollFree: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "zipcode" $zipcode "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/local" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "prefix": $prefix, "city": $city, "state": $state, "zipcode": $zipcode, "fields": $fields} | compact), body: null}
}

# Find number regions
#
# GET /numbers/regions
# operationId: findNumberRegions
export def "numbers-regions find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --prefix: string # A 4-7 digit prefix
  --city: string # A city name
  --city-prefix: string # ~
  --state: string # A two-letter state code. Example: CA, IL, etc.
  --zipcode: string # A five-digit Zipcode
  --country: string # ~
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<items: table<city: string, country: string, latitude: float, longitude: float, prefix: string, state: string, timeZone: string, zipcode: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "cityPrefix" $city_prefix "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "zipcode" $zipcode "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "prefix": $prefix, "city": $city, "cityPrefix": $city_prefix, "state": $state, "zipcode": $zipcode, "country": $country, "fields": $fields} | compact), body: null}
}

# Find tollfree numbers
#
# GET /numbers/tollfree
# operationId: findNumbersTollfree
export def "numbers-tollfree find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pattern: string # Filter toll free numbers by prefix, pattern must be 3 char long and should end with '*'. Examples: 8**, 85*, 87* (but 855 will fail because pattern must end with '*').
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<items: table<nationalFormat: string, number: string, region: record, sendEmailOnCreate: bool, tollFree: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pattern" $pattern "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/tollfree" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pattern": $pattern, "limit": $limit, "fields": $fields} | compact), body: null}
}

# Find orders
#
# GET /orders
# operationId: findOrders
export def "orders find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 20)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --status: list<string> # Filter by order status, accepts multiple values in comma separated string, available values: [PROCESSING, FINISHED, PAYMENT_ERROR, VOID, WAIT_FOR_PAYMENT, PARTIALLY_ADJUSTED, ADJUSTED]
  --interval-begin: int # Start of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 (format: int64)
  --interval-end: int # End of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 (format: int64)
]: nothing -> record<items: table<created: int, id: int, keywords: record, localNumbers: record, salesTax: float, status: string, summary: float, tollFreeNumbers: record, total: float, totalCost: float>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "status" $status "multi") (serialize-qp "intervalBegin" $interval_begin "scalar") (serialize-qp "intervalEnd" $interval_end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "fields": $fields, "status": $status, "intervalBegin": $interval_begin, "intervalEnd": $interval_end} | compact), body: null}
}

# Purchase keywords
#
# POST /orders/keywords
# operationId: orderKeywords
export def "orders-keywords create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --keywords: list<string> # A list of keywords
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/keywords" $qp)
  let req_body = {"keywords": $keywords} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"fields": $fields} | compact), body: $req_body}
}

# Purchase numbers
#
# POST /orders/numbers
# operationId: orderNumbers
export def "orders-numbers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --city: string # City of requested numbers
  --local-count: int # Total count of local numbers requested (format: int32)
  --numbers: list<string> # A list of phone numbers in E.164 format (11-digit) to buy. Example: 12132000384
  --prefix: string # Country prefix of requested numbers
  --promo: string # ~
  --state: string # A two-letter state code of requested numbers
  --toll-free-count: int # Total count of toll-free numbers requested (format: int32)
  --zipcode: string # A five-digit Zip code of requested numbers
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/numbers" $qp)
  let req_body = {"city": $city, "localCount": $local_count, "numbers": $numbers, "prefix": $prefix, "promo": $promo, "state": $state, "tollFreeCount": $toll_free_count, "zipcode": $zipcode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"fields": $fields} | compact), body: $req_body}
}

# Find a specific order
#
# GET /orders/{id}
# operationId: getOrder
export def "orders get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<created: int, id: int, keywords: record<fulfilled: list<string>, ordered: int, unitCost: float>, localNumbers: record<fulfilled: list<string>, ordered: int, unitCost: float>, salesTax: float, status: string, summary: float, tollFreeNumbers: record<fulfilled: list<string>, ordered: int, unitCost: float>, total: float, totalCost: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/orders/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Get delivery reports by ad hoc criteria
#
# GET /reports/delivery
# operationId: getDeliveryReports
export def "reports-delivery get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # ~
  --end-date: string # ~
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --campaign-id: int # ~ (format: int64)
  --from-number: string # ~
  --to-number: string # ~
  --delivery-category: string@delivery-category-completer # ~
  --delivery-state: string@delivery-state-completer # ~
  --carrier: string # ~
  --message-text: string # ~
]: nothing -> record<items: table<campaignId: int, carrier: string, deliveryCategory: string, deliveryState: string, fromNumber: string, messageText: string, toNumber: string, updated: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "campaignId" $campaign_id "scalar") (serialize-qp "fromNumber" $from_number "scalar") (serialize-qp "toNumber" $to_number "scalar") (serialize-qp "deliveryCategory" $delivery_category "scalar") (serialize-qp "deliveryState" $delivery_state "scalar") (serialize-qp "carrier" $carrier "scalar") (serialize-qp "messageText" $message_text "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/delivery" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startDate": $start_date, "endDate": $end_date, "limit": $limit, "offset": $offset, "campaignId": $campaign_id, "fromNumber": $from_number, "toNumber": $to_number, "deliveryCategory": $delivery_category, "deliveryState": $delivery_state, "carrier": $carrier, "messageText": $message_text} | compact), body: null}
}

# Find texts
#
# GET /texts
# operationId: findTexts
export def "texts find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<int> # List of Text ids to search for, if ids specified other query params ignored
  --campaign-id: int # An id of a campaign, queries for texts inside a particular campaign. Specify null to list texts of all campaigns or 0 for a default campaign (format: int64)
  --batch-id: int # An Id of a contact batch, queries for texts which are used in the particular contact batch (format: int64)
  --from-number: string # A phone number in E.164 format (11-digit). Example: 12132000384, 67076
  --to-number: string # A phone number in E.164 format (11-digit). Example: 12132000384, 67076
  --label: string # A label of a text message
  --states: string # Expected text statuses in comma separated string, available values: READY, SELECTED, CALLBACK, FINISHED, DISABLED, DNC, DUP, INVALID, TIMEOUT, PERIOD_LIMIT. See [call states and results](https://developers.callfire.com/results-responses-errors.html)
  --results: string # Expected text results in comma separated string, available values: SENT, RECEIVED, DNT, TOO_BIG, INTERNAL_ERROR, CARRIER_ERROR, CARRIER_TEMP_ERROR, UNDIALED. See [call states and results](https://developers.callfire.com/results-responses-errors.html)
  --inbound: oneof<nothing, bool> # Specify true for inbound or false for outbounds. Do not specify this parameter if you need to get both inbound and outbound texts listed in response
  --interval-begin: int # Start of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 (format: int64)
  --interval-end: int # End of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 (format: int64)
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 10)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<items: table<attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list, media: list, message: string, modified: int, records: list, state: string, toNumber: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi") (serialize-qp "campaignId" $campaign_id "scalar") (serialize-qp "batchId" $batch_id "scalar") (serialize-qp "fromNumber" $from_number "scalar") (serialize-qp "toNumber" $to_number "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "states" $states "scalar") (serialize-qp "results" $results "scalar") (serialize-qp "inbound" $inbound "scalar") (serialize-qp "intervalBegin" $interval_begin "scalar") (serialize-qp "intervalEnd" $interval_end "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/texts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "campaignId": $campaign_id, "batchId": $batch_id, "fromNumber": $from_number, "toNumber": $to_number, "label": $label, "states": $states, "results": $results, "inbound": $inbound, "intervalBegin": $interval_begin, "intervalEnd": $interval_end, "limit": $limit, "offset": $offset, "fields": $fields} | compact), body: null}
}

# Send texts
#
# POST /texts
# operationId: sendTexts
export def "texts send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --campaign-id: int # Specifies a campaignId to send texts through a previously created campaign (format: int64)
  --default-message: string # Text message can be overridden by TextRecipient.message field. If multiple recipients have the same text message to a different recipients it is better to specify a single default message and do not duplicate it in each recipient.
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients
  --body: list
]: any -> record<items: table<attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list, media: list, message: string, modified: int, records: list, state: string, toNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "campaignId" $campaign_id "scalar") (serialize-qp "defaultMessage" $default_message "scalar") (serialize-qp "strictValidation" $strict_validation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/texts" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"fields": $fields, "campaignId": $campaign_id, "defaultMessage": $default_message, "strictValidation": $strict_validation} | compact), body: $req_body}
}

# Find auto replies
#
# GET /texts/auto-replys
# operationId: findTextAutoReplys
export def "texts-auto-replys find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --number: string # Phone number in E.164 format (11-digit) which contains a TextAutoReply. Example: 12132000384. If number is empty then operator returns all autoreplies configured for the user's account
]: nothing -> record<items: table<id: int, keyword: string, match: string, message: string, number: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/texts/auto-replys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "limit": $limit, "offset": $offset, "number": $number} | compact), body: null}
}

# Create an auto reply
#
# POST /texts/auto-replys
# operationId: createTextAutoReply
export def "texts-auto-replys create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # An id of a text auto reply (format: int64)
  --keyword: string # Setup autoreply for a given keyword
  --body-match: string # Text to match. If it is set then autoreply will be sent to a person who texted message with matched text. Case insensitive, if parameter is not specified then all texts will be matched
  --message: string # A text message to return as an auto reply
  --number: string # Setup autoreply for a given phone number, E.164 format (11-digit). Example: 12132000384
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/texts/auto-replys")
  let req_body = {"id": $id, "keyword": $keyword, "match": $body_match, "message": $message, "number": $number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an auto reply
#
# DELETE /texts/auto-replys/{id}
# operationId: deleteTextAutoReply
export def "texts-auto-replys delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/texts/auto-replys/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find a specific auto reply
#
# GET /texts/auto-replys/{id}
# operationId: getTextAutoReply
export def "texts-auto-replys get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<id: int, keyword: string, match: string, message: string, number: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/texts/auto-replys/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Find text broadcasts
#
# GET /texts/broadcasts
# operationId: findTextBroadcasts
export def "texts-broadcasts find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A name of text broadcast
  --label: string # A label of a text broadcast
  --running: oneof<nothing, bool> # Returns broadcasts only in running state.
  --scheduled: oneof<nothing, bool> # Specify whether the campaigns should be scheduled or not
  --interval-begin: int # Start of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
  --interval-end: int # End of the find time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 10)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<items: table<bigMessageStrategy: string, fromNumber: string, id: int, labels: list, lastModified: int, localTimeRestriction: record, maxActive: int, media: list, message: string, name: string, recipients: list, resumeNextDay: bool, schedules: list, status: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "running" $running "scalar") (serialize-qp "scheduled" $scheduled "scalar") (serialize-qp "intervalBegin" $interval_begin "scalar") (serialize-qp "intervalEnd" $interval_end "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/texts/broadcasts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "label": $label, "running": $running, "scheduled": $scheduled, "intervalBegin": $interval_begin, "intervalEnd": $interval_end, "limit": $limit, "offset": $offset, "fields": $fields} | compact), body: null}
}

# Create a text broadcast
#
# POST /texts/broadcasts
# operationId: createTextBroadcast
# --localTimeRestriction shape: {beginHour?: int, beginMinute?: int, enabled?: bool, endHour?: int, endMinute?: int}
# --media item shape: {accountId?: int, created?: int, id?: int, lengthInBytes?: int, mediaType?: string, name?: string, publicUrl?: string}
# --recipients item shape: {attributes?: record, contactId?: int, fromNumber?: string, media?: list, message?: string, phoneNumber?: string}
# --schedules item shape: {campaignId?: int, daysOfWeek?: list<string>, id?: int, startDate?: record, startTimeOfDay?: record, stopDate?: record, stopTimeOfDay?: record, timeZone?: string}
export def "texts-broadcasts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: oneof<nothing, bool> # If true then starts the campaign immediately (not required).
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --big-message-strategy: string@big-message-strategy-completer # If message length exceeds 160 characters, multiple messages will be sent, SEND_MULTIPLE strategy is chosen by default. Available values: SEND_MULTIPLE - send text as multiple messages, DO_NOT_SEND - do not send text if it exceeds 160 characters, TRIM - trims text message to 160 characters
  --from-number: string # A phone number in E.164 format (11-digit) or short code. Example: 12132000384, 67076, etc
  --id: int # A unique id of a broadcast (format: int64)
  --labels: list<string> # A labels of a broadcast
  --local-time-restriction: record # Represents a range of time during which CallFire will send a call or text to recipients. Timeframe uses the local timezone of recipient's number — shape: {beginHour?: int, beginMinute?: int, enabled?: bool, endHour?: int, endMinute?: int}
  --max-active: int # A maximum number of texts that CallFire dials at once (format: int32)
  --media: list # ~ — item shape: {accountId?: int, created?: int, id?: int, lengthInBytes?: int, mediaType?: string, name?: string, publicUrl?: string}
  --message: string # A text message
  --name: string # A name of a broadcast
  --recipients: list # Recipients of a text campaign, can be an existing contacts or a new one — item shape: {attributes?: record, contactId?: int, fromNumber?: string, media?: list, message?: string, phoneNumber?: string}
  --resume-next-day: oneof<nothing, bool> # ~
  --schedules: list # ~ — item shape: {campaignId?: int, daysOfWeek?: list<string>, id?: int, startDate?: record, startTimeOfDay?: record, stopDate?: record, stopTimeOfDay?: record, timeZone?: string}
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "strictValidation" $strict_validation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/texts/broadcasts" $qp)
  let req_body = {"bigMessageStrategy": $big_message_strategy, "fromNumber": $from_number, "id": $id, "labels": $labels, "localTimeRestriction": $local_time_restriction, "maxActive": $max_active, "media": $media, "message": $message, "name": $name, "recipients": $recipients, "resumeNextDay": $resume_next_day, "schedules": $schedules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"start": $start, "strictValidation": $strict_validation} | compact), body: $req_body}
}

# Find a specific text broadcast
#
# GET /texts/broadcasts/{id}
# operationId: getTextBroadcast
export def "texts-broadcasts get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<bigMessageStrategy: string, fromNumber: string, id: int, labels: list<string>, lastModified: int, localTimeRestriction: record<beginHour: int, beginMinute: int, enabled: bool, endHour: int, endMinute: int>, maxActive: int, media: table<accountId: int, created: int, id: int, lengthInBytes: int, mediaType: string, name: string, publicUrl: string>, message: string, name: string, recipients: table<attributes: record, contactId: int, fromNumber: string, media: list, message: string, phoneNumber: string>, resumeNextDay: bool, schedules: table<campaignId: int, daysOfWeek: list, id: int, startDate: record, startTimeOfDay: record, stopDate: record, stopTimeOfDay: record, timeZone: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/texts/broadcasts/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Update a text broadcast
#
# PUT /texts/broadcasts/{id}
# operationId: updateTextBroadcast
# --localTimeRestriction shape: {beginHour?: int, beginMinute?: int, enabled?: bool, endHour?: int, endMinute?: int}
# --media item shape: {accountId?: int, created?: int, id?: int, lengthInBytes?: int, mediaType?: string, name?: string, publicUrl?: string}
# --recipients item shape: {attributes?: record, contactId?: int, fromNumber?: string, media?: list, message?: string, phoneNumber?: string}
# --schedules item shape: {campaignId?: int, daysOfWeek?: list<string>, id?: int, startDate?: record, startTimeOfDay?: record, stopDate?: record, stopTimeOfDay?: record, timeZone?: string}
export def "texts-broadcasts update" [
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
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --big-message-strategy: string@big-message-strategy-completer # If message length exceeds 160 characters, multiple messages will be sent, SEND_MULTIPLE strategy is chosen by default. Available values: SEND_MULTIPLE - send text as multiple messages, DO_NOT_SEND - do not send text if it exceeds 160 characters, TRIM - trims text message to 160 characters
  --from-number: string # A phone number in E.164 format (11-digit) or short code. Example: 12132000384, 67076, etc
  --body-id: int # A unique id of a broadcast (format: int64)
  --labels: list<string> # A labels of a broadcast
  --local-time-restriction: record # Represents a range of time during which CallFire will send a call or text to recipients. Timeframe uses the local timezone of recipient's number — shape: {beginHour?: int, beginMinute?: int, enabled?: bool, endHour?: int, endMinute?: int}
  --max-active: int # A maximum number of texts that CallFire dials at once (format: int32)
  --media: list # ~ — item shape: {accountId?: int, created?: int, id?: int, lengthInBytes?: int, mediaType?: string, name?: string, publicUrl?: string}
  --message: string # A text message
  --name: string # A name of a broadcast
  --recipients: list # Recipients of a text campaign, can be an existing contacts or a new one — item shape: {attributes?: record, contactId?: int, fromNumber?: string, media?: list, message?: string, phoneNumber?: string}
  --resume-next-day: oneof<nothing, bool> # ~
  --schedules: list # ~ — item shape: {campaignId?: int, daysOfWeek?: list<string>, id?: int, startDate?: record, startTimeOfDay?: record, stopDate?: record, stopTimeOfDay?: record, timeZone?: string}
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "strictValidation" $strict_validation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/texts/broadcasts/{id}") $qp)
  let req_body = {"bigMessageStrategy": $big_message_strategy, "fromNumber": $from_number, "id": $body_id, "labels": $labels, "localTimeRestriction": $local_time_restriction, "maxActive": $max_active, "media": $media, "message": $message, "name": $name, "recipients": $recipients, "resumeNextDay": $resume_next_day, "schedules": $schedules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"strictValidation": $strict_validation} | compact), body: $req_body}
}

# Archive text broadcast
#
# POST /texts/broadcasts/{id}/archive
# operationId: archiveTextBroadcast
export def "texts-broadcasts-archive archive" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/texts/broadcasts/{id}/archive"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find batches in a text broadcast
#
# GET /texts/broadcasts/{id}/batches
# operationId: getTextBroadcastBatches
export def "texts-broadcasts-batches get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
]: nothing -> record<items: table<broadcastId: int, created: int, enabled: bool, id: int, name: string, remaining: int, size: int, status: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/texts/broadcasts/{id}/batches") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "limit": $limit, "offset": $offset} | compact), body: null}
}

# Add batches to a text broadcast
#
# POST /texts/broadcasts/{id}/batches
# operationId: addTextBroadcastBatch
# --recipients item shape: {attributes?: record, contactId?: int, fromNumber?: string, phoneNumber?: string}
export def "texts-broadcasts-batches create-batch" [
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
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --contact-list-id: int # An id of existing contact list (format: int64)
  --name: string # A name of batch
  --recipients: list # A list of Recipient objects. For each recipient you can set its phone number or existing contact id to use contact which already exists in account — item shape: {attributes?: record, contactId?: int, fromNumber?: string, phoneNumber?: string}
  --scrub-duplicates: oneof<nothing, bool> # Removes duplicate recipients from batch if true
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "strictValidation" $strict_validation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/texts/broadcasts/{id}/batches") $qp)
  let req_body = {"contactListId": $contact_list_id, "name": $name, "recipients": $recipients, "scrubDuplicates": $scrub_duplicates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"strictValidation": $strict_validation} | compact), body: $req_body}
}

# Add recipients to a text broadcast
#
# POST /texts/broadcasts/{id}/recipients
# operationId: addTextBroadcastRecipients
export def "texts-broadcasts-recipients create" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --strict-validation: oneof<nothing, bool> # Turns on strict validation for recipients. System will reply with BAD_REQUEST(400) if strictValidation = true and one of numbers didn't pass validation
  --body: list
]: any -> record<items: table<attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list, media: list, message: string, modified: int, records: list, state: string, toNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "strictValidation" $strict_validation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/texts/broadcasts/{id}/recipients") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"fields": $fields, "strictValidation": $strict_validation} | compact), body: $req_body}
}

# Start text broadcast
#
# POST /texts/broadcasts/{id}/start
# operationId: startTextBroadcast
export def "texts-broadcasts-start start" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/texts/broadcasts/{id}/start"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get statistics on text broadcast
#
# GET /texts/broadcasts/{id}/stats
# operationId: getTextBroadcastStats
export def "texts-broadcasts-stats get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --begin: int # Start of a search find time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
  --end: int # End of a search time interval, formatted in unix time milliseconds. Example: 1473781817000 for Sat, 05 Jan 1985 14:03:37 GMT (format: int64)
]: nothing -> record<billedAmount: float, doNotTextCount: int, errorCount: int, recievedCount: int, remainingOutboundCount: int, sentCount: int, tooBigCount: int, totalOutboundCount: int, unsentCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "begin" $begin "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/texts/broadcasts/{id}/stats") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "begin": $begin, "end": $end} | compact), body: null}
}

# Stop text broadcast
#
# POST /texts/broadcasts/{id}/stop
# operationId: stopTextBroadcast
export def "texts-broadcasts-stop stop" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/texts/broadcasts/{id}/stop"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find texts in a text broadcast
#
# GET /texts/broadcasts/{id}/texts
# operationId: getTextBroadcastTexts
export def "texts-broadcasts-texts get" [
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
  --batch-id: int # ~ (format: int64)
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
]: nothing -> record<items: table<attributes: record, batchId: int, campaignId: int, contact: record, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list, media: list, message: string, modified: int, records: list, state: string, toNumber: string>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "batchId" $batch_id "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/texts/broadcasts/{id}/texts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"batchId": $batch_id, "fields": $fields, "limit": $limit, "offset": $offset} | compact), body: null}
}

# Disable/enable undialed recipients in broadcast
#
# POST /texts/broadcasts/{id}/toggleRecipientsStatus
# operationId: toggleTextBroadcastRecipientsStatus
export def "texts-broadcasts-toggle-recipients-status create" [
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
  --enable: oneof<nothing, bool> # Flag which indicate what to do with texts (true will enable texts in DISABLED status and vice versa) (default: false)
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "enable" $enable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/texts/broadcasts/{id}/toggleRecipientsStatus") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"enable": $enable} | compact), body: $req_body}
}

# Find a specific text
#
# GET /texts/{id}
# operationId: getText
export def "texts get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<attributes: record, batchId: int, campaignId: int, contact: record<deleted: bool, externalId: string, externalSystem: string, extraPhone1: string, extraPhone2: string, extraPhone3: string, firstName: string, homePhone: string, id: int, lastName: string, mobilePhone: string, properties: record, workPhone: string, zipcode: string>, created: int, finalTextResult: string, fromNumber: string, id: int, inbound: bool, labels: list<string>, media: table<accountId: int, created: int, id: int, lengthInBytes: int, mediaType: string, name: string, publicUrl: string>, message: string, modified: int, records: table<billedAmount: float, callerName: string, finishTime: int, id: int, labels: list, message: string, switchId: string, textResult: string, toNumber: string>, state: string, toNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/texts/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Find webhooks
#
# GET /webhooks
# operationId: findWebhooks
export def "webhooks find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
  --limit: int # To set the maximum number of records to return in a paged list response. The default is 100 (format: int32, default: 100)
  --offset: int # Offset to the start of a given page. The default is 0. Check [pagination](https://developers.callfire.com/docs.html#pagination) page for more information about pagination in CallFire API. (format: int32, default: 0)
  --name: string # A name of a webhook
  --resource: string # A name of a resource, available values: 'CccCampaign', 'CallBroadcast', 'TextBroadcast', 'OutboundCall', 'OutboundText', 'InboundCall', 'InboundText', 'ContactList'
  --event: string # A name of event, available values: 'started', 'stopped', 'finished'
  --callback: string # A callback URL
  --enabled: oneof<nothing, bool> # Specifies whether webhook is enabled
]: nothing -> record<items: table<callback: string, createdAt: int, enabled: bool, events: list, expiresAt: int, fields: string, id: int, name: string, nonStrictSsl: bool, resource: string, secret: string, singleUse: bool, updatedAt: int>, limit: int, offset: int, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "resource" $resource "scalar") (serialize-qp "event" $event "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "enabled" $enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "limit": $limit, "offset": $offset, "name": $name, "resource": $resource, "event": $event, "callback": $callback, "enabled": $enabled} | compact), body: null}
}

# Create a webhook
#
# POST /webhooks
# operationId: createWebhook
export def "webhooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # URL that webhook will send POST to on resource event trigger
  --enabled: oneof<nothing, bool> # A parameter which allows the webhook to send requests to unknown ssl endpoints (ssl certificate verification is disabled)
  --events: list<string> # Comma separated list of events on resource that will trigger callbacks (ex: STARTED, STOPPED, FINISHED, etc...).
  --expires-at: int # ~ (format: int64)
  --fields: string # A limit callback response to a particular fields
  --id: int # An id of a webhook (format: int64)
  --name: string # A name of a webhook
  --non-strict-ssl: oneof<nothing, bool> # A parameter which allows the webhook to send requests to unknown ssl endpoints (ssl certificate verification is disabled)
  --resource: string # A resource name that webhook is watching events on. Use GET /webhooks/resources to determine resources and events available (ex: InboundCall, OutboundCall, InboundText, OutboundText, CallBroadcast, TextBroadcast, etc...)
  --secret: string # Webhook secret token which is used as a signing key to HmacSHA1 hash of json payload which is returned in 'X-CallFire-Signature' header. This header can be used to verify callback POST is coming from CallFire. See [security guide](https://developers.callfire.com/security-guide.html)
  --single-use: oneof<nothing, bool> # If true is set then webhook triggers only once. Afterwards the webhook will be deleted
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let req_body = {"callback": $callback, "enabled": $enabled, "events": $events, "expiresAt": $expires_at, "fields": $fields, "id": $id, "name": $name, "nonStrictSsl": $non_strict_ssl, "resource": $resource, "secret": $secret, "singleUse": $single_use} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Find webhook resources
#
# GET /webhooks/resources
# operationId: findWebhookResources
export def "webhooks-resources find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<items: table<resource: string, supportedEvents: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks/resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Find specific webhook resource
#
# GET /webhooks/resources/{resource}
# operationId: getWebhookResource
export def "webhooks-resources get" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<resource: string, supportedEvents: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: (encode-path-segment $resource)} | format pattern "/webhooks/resources/{resource}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Delete a webhook
#
# DELETE /webhooks/{id}
# operationId: deleteWebhook
export def "webhooks delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/webhooks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find a specific webhook
#
# GET /webhooks/{id}
# operationId: getWebhook
export def "webhooks get" [
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
  --fields: string # Limit fields received in response. E.g. fields: id, name or fields items (id, name), see more at [partial response](https://developers.callfire.com/docs.html#partial-response) page.
]: nothing -> record<callback: string, createdAt: int, enabled: bool, events: list<string>, expiresAt: int, fields: string, id: int, name: string, nonStrictSsl: bool, resource: string, secret: string, singleUse: bool, updatedAt: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/webhooks/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# Update a webhook
#
# PUT /webhooks/{id}
# operationId: updateWebhook
export def "webhooks update" [
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
  --callback: string # URL that webhook will send POST to on resource event trigger
  --enabled: oneof<nothing, bool> # A parameter which allows the webhook to send requests to unknown ssl endpoints (ssl certificate verification is disabled)
  --events: list<string> # Comma separated list of events on resource that will trigger callbacks (ex: STARTED, STOPPED, FINISHED, etc...).
  --expires-at: int # ~ (format: int64)
  --fields: string # A limit callback response to a particular fields
  --body-id: int # An id of a webhook (format: int64)
  --name: string # A name of a webhook
  --non-strict-ssl: oneof<nothing, bool> # A parameter which allows the webhook to send requests to unknown ssl endpoints (ssl certificate verification is disabled)
  --resource: string # A resource name that webhook is watching events on. Use GET /webhooks/resources to determine resources and events available (ex: InboundCall, OutboundCall, InboundText, OutboundText, CallBroadcast, TextBroadcast, etc...)
  --secret: string # Webhook secret token which is used as a signing key to HmacSHA1 hash of json payload which is returned in 'X-CallFire-Signature' header. This header can be used to verify callback POST is coming from CallFire. See [security guide](https://developers.callfire.com/security-guide.html)
  --single-use: oneof<nothing, bool> # If true is set then webhook triggers only once. Afterwards the webhook will be deleted
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/webhooks/{id}"))
  let req_body = {"callback": $callback, "enabled": $enabled, "events": $events, "expiresAt": $expires_at, "fields": $fields, "id": $body_id, "name": $name, "nonStrictSsl": $non_strict_ssl, "resource": $resource, "secret": $secret, "singleUse": $single_use} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
