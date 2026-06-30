# Auto-generated client for Voice API v1.3.10
# Source: https://api.apis.guru/v2/specs/nexmo.com/voice/1.3.10/openapi.json
# Auth: --token flag or $env.VOICE_API_TOKEN

const BASE_URL = "https://api.nexmo.com/v1/calls"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o VOICE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.nexmo.com/v1/calls"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["answered" "busy" "cancelled" "completed" "failed" "machine" "rejected" "ringing" "started" "timeout" "unanswered"] }
def order-completer [] { ["asc" "desc"] }
def action-completer [] { ["transfer"] }
def language-completer [] { ["ar" "ca-ES" "cmn-CN" "cmn-TW" "cs-CZ" "cy-GB" "da-DK" "de-DE" "el-GR" "en-AU" "en-GB" "en-GB-WLS" "en-IN" "en-US" "en-ZA" "es-ES" "es-MX" "es-US" "eu-ES" "fi-FI" "fil-PH" "fr-CA" "fr-FR" "he-IL" "hi-IN" "hu-HU" "id-ID" "is-IS" "it-IT" "ja-JP" "ko-KR" "nb-NO" "nl-NL" "no-NO" "pl-PL" "pt-BR" "pt-PT" "ro-RO" "ru-RU" "sk-SK" "sv-SE" "th-TH" "tr-TR" "uk-UA" "vi-VN" "yue-CN"] }
def voice-name-completer [] { ["Aditi" "Agnieszka" "Alva" "Amy" "Astrid" "Bianca" "Brian" "Carla" "Carmen" "Carmit" "Catarina" "Celine" "Cem" "Chantal" "Chipmunk" "Conchita" "Cristiano" "Damayanti" "Dora" "Emma" "Empar" "Enrique" "Eric" "Ewa" "Felipe" "Filiz" "Geraint" "Giorgio" "Gwyneth" "Hans" "Henrik" "Ines" "Ioana" "Iveta" "Ivy" "Jacek" "Jan" "Jennifer" "Joana" "Joanna" "Joey" "Jordi" "Justin" "Kanya" "Karl" "Kendra" "Kimberly" "Laila" "Laura" "Lea" "Lekha" "Liv" "Lotte" "Lucia" "Luciana" "Mads" "Maged" "Maja" "Mariska" "Marlene" "Mathieu" "Matthew" "Maxim" "Mei-Jia" "Melina" "Mia" "Miguel" "Miren" "Mizuki" "Montserrat" "Naja" "Nicole" "Nikos" "Nora" "Oskar" "Penelope" "Raveena" "Ricardo" "Ruben" "Russell" "Salli" "Satu" "Seoyeon" "Sin-Ji" "Sora" "Takumi" "Tarik" "Tatyana" "Tessa" "Tian-Tian" "Vicki" "Vitoria" "Yelda" "Zeina" "Zhiyu" "Zuzana"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "calls list" } } | get name | first)
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

# Get details of your calls
#
# GET /
# operationId: getCalls
export def "calls list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Filter by call status (e.g. started)
  --date-start: string # Return the records that occurred after this point in time (format: date-time, e.g. 2016-11-14T07:45:14Z)
  --date-end: string # Return the records that occurred before this point in time (format: date-time, e.g. 2016-11-14T07:45:14Z)
  --page-size: int # Return this amount of records in the response (default: 10)
  --record-index: int # Return calls from this index in the response (default: 0)
  --order: string@order-completer # Either ascending or descending order. (default: asc)
  --conversation-uuid: string # Return all the records associated with a specific conversation. (format: uuid, e.g. CON-f972836a-550f-45fa-956c-12a2ab5b7d22)
]: nothing -> record<_embedded: record<calls: list<record>>, _links: record<self: record<href: string>>, count: int, page_size: int, record_index: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "date_start" $date_start "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "record_index" $record_index "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "conversation_uuid" $conversation_uuid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"status": $status, "date_start": $date_start, "date_end": $date_end, "page_size": $page_size, "record_index": $record_index, "order": $order, "conversation_uuid": $conversation_uuid} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an outbound call
#
# POST /
# operationId: createCall
export def "calls create" [
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
]: any -> record<conversation_uuid: string, direction: string, status: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = $body
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get detail of a specific call
#
# GET /{uuid}
# operationId: getCall
export def "calls get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<self: record<href: string>>, conversation_uuid: string, direction: string, duration: string, end_time: string, from: record<number: string, type: string>, network: string, price: string, rate: string, start_time: string, status: string, to: record<number: string, type: string>, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($uuid | is-empty) { error make --unspanned { msg: "path parameter 'uuid' must be non-empty" } }
  let full_url = (build-url $base ({uuid: (encode-path-segment $uuid)} | format pattern "/{uuid}") $auth.query)
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

# Modify an in progress call
#
# PUT /{uuid}
# operationId: updateCall
# --destination shape: {ncco: list, type: string}
export def "calls update" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer # Transfer the call to a new NCCO (e.g. transfer)
  --destination: record # shape: {ncco: list, type: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($uuid | is-empty) { error make --unspanned { msg: "path parameter 'uuid' must be non-empty" } }
  let full_url = (build-url $base ({uuid: (encode-path-segment $uuid)} | format pattern "/{uuid}") $auth.query)
  let req_body = {"action": $action, "destination": $destination} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Play DTMF tones into a call
#
# PUT /{uuid}/dtmf
# operationId: startDTMF
export def "dtmf start" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --digits: string # The digits to send (e.g. 1713)
]: any -> record<message: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($uuid | is-empty) { error make --unspanned { msg: "path parameter 'uuid' must be non-empty" } }
  let full_url = (build-url $base ({uuid: (encode-path-segment $uuid)} | format pattern "/{uuid}/dtmf") $auth.query)
  let req_body = {"digits": $digits} | compact
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

# Stop playing an audio file into a call
#
# DELETE /{uuid}/stream
# operationId: stopStream
export def "stream stop" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($uuid | is-empty) { error make --unspanned { msg: "path parameter 'uuid' must be non-empty" } }
  let full_url = (build-url $base ({uuid: (encode-path-segment $uuid)} | format pattern "/{uuid}/stream") $auth.query)
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

# Play an audio file into a call
#
# PUT /{uuid}/stream
# operationId: startStream
export def "stream start" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: string # Set the audio level of the stream in the range `-1 >= level <= 1` with a precision of 0.1. The default value is 0. (default: 0, e.g. 0.4)
  --body-loop: int # the number of times to play the file, 0 for infinite (default: 1)
  stream_url: list<string> # e.g. [https://example.com/waiting.mp3]
]: any -> record<message: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($uuid | is-empty) { error make --unspanned { msg: "path parameter 'uuid' must be non-empty" } }
  let full_url = (build-url $base ({uuid: (encode-path-segment $uuid)} | format pattern "/{uuid}/stream") $auth.query)
  let req_body = {"level": $level, "loop": $body_loop, "stream_url": $stream_url} | compact
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

# Stop text to speech in a call
#
# DELETE /{uuid}/talk
# operationId: stopTalk
export def "talk stop" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($uuid | is-empty) { error make --unspanned { msg: "path parameter 'uuid' must be non-empty" } }
  let full_url = (build-url $base ({uuid: (encode-path-segment $uuid)} | format pattern "/{uuid}/talk") $auth.query)
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

# Play text to speech into a call
#
# PUT /{uuid}/talk
# operationId: startTalk
@deprecated --flag voice-name
export def "talk start" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string@language-completer # The language to use (default: en-US)
  --level: string # The volume level that the speech is played. This can be any value between `-1` to `1` in `0.1` increments, with `0` being the default. (default: 0, e.g. 0.4)
  --body-loop: int # The number of times to repeat the text the file, 0 for infinite (default: 1)
  --premium: oneof<nothing, bool> # Set to true to use the premium version of the specified style if available, otherwise the standard version will be used. The default value is false. You can find more information about Premium Voices in the [Text-To-Speech guide](/voice/voice-api/guides/text-to-speech#premium-voices). (default: false)
  --style: int # The vocal style (vocal range, tessitura, and timbre) to use (default: 0)
  text: string # The text to read (e.g. Hello. How are you today?)
  --voice-name: string@voice-name-completer # DEPRECATED The voice & language to use (DEPRECATED, default: Kimberly)
]: any -> record<message: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($uuid | is-empty) { error make --unspanned { msg: "path parameter 'uuid' must be non-empty" } }
  let full_url = (build-url $base ({uuid: (encode-path-segment $uuid)} | format pattern "/{uuid}/talk") $auth.query)
  let req_body = {"language": $language, "level": $level, "loop": $body_loop, "premium": $premium, "style": $style, "text": $text, "voice_name": $voice_name} | compact
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
