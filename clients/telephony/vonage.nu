# Auto-generated client for Voice API v1.3.10
# Source: https://api.apis.guru/v2/specs/nexmo.com/voice/1.3.10/openapi.json
# Auth: --token flag or $env.VOICE_API_TOKEN

const BASE_URL = "https://api.nexmo.com/v1/calls"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VOICE_API_TOKEN | default "" }
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
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
  --status: string@status-completer # Filter by call status (e.g. started)
  --date-start: string # Return the records that occurred after this point in time (format: date-time, e.g. 2016-11-14T07:45:14Z)
  --date-end: string # Return the records that occurred before this point in time (format: date-time, e.g. 2016-11-14T07:45:14Z)
  --page-size: int # Return this amount of records in the response (default: 10)
  --record-index: int # Return calls from this index in the response (default: 0)
  --order: string@order-completer # Either ascending or  descending order. (default: asc)
  --conversation-uuid: string # Return all the records associated with a specific conversation. (format: uuid, e.g. CON-f972836a-550f-45fa-956c-12a2ab5b7d22)
]: nothing -> record<_embedded: record<calls: list<record>>, _links: record<self: record<href: string>>, count: int, page_size: int, record_index: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "date_start" $date_start "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "record_index" $record_index "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "conversation_uuid" $conversation_uuid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an outbound call
#
# POST /
# operationId: createCall
export def "calls createCall" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<conversation_uuid: string, direction: string, status: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<_links: record<self: record<href: string>>, conversation_uuid: string, direction: string, duration: string, end_time: string, from: record<number: string, type: string>, network: string, price: string, rate: string, start_time: string, status: string, to: record<number: string, type: string>, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify an in progress call
#
# PUT /{uuid}
# operationId: updateCall
# --destination shape: {ncco: list, type: string}
export def "calls updateCall" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: string@action-completer # Transfer the call to a new NCCO (e.g. transfer)
  --destination: record # shape: {ncco: list, type: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($uuid)")
  let body = {action: $action, destination: $destination} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Play DTMF tones into a call
#
# PUT /{uuid}/dtmf
# operationId: startDTMF
export def "dtmf startDTMF" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --digits: string # The digits to send (e.g. 1713)
]: any -> record<message: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($uuid)/dtmf")
  let body = {digits: $digits} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stop playing an audio file into a call
#
# DELETE /{uuid}/stream
# operationId: stopStream
export def "stream stopStream" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($uuid)/stream")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Play an audio file into a call
#
# PUT /{uuid}/stream
# operationId: startStream
export def "stream startStream" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --level: string # Set the audio level of the stream in the range `-1 >= level <= 1` with a precision of 0.1. The default value is 0. (default: 0, e.g. 0.4)
  --body-loop: int # the number of times to play the file, 0 for infinite (default: 1)
  stream_url: list # e.g. [https://example.com/waiting.mp3]
]: any -> record<message: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($uuid)/stream")
  let body = {level: $level, loop: $body_loop, stream_url: $stream_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Stop text to speech in a call
#
# DELETE /{uuid}/talk
# operationId: stopTalk
export def "talk stopTalk" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($uuid)/talk")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Play text to speech into a call
#
# PUT /{uuid}/talk
# operationId: startTalk
@deprecated --flag voice-name
export def "talk startTalk" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string@language-completer # The language to use (default: en-US)
  --level: string # The volume level that the speech is played. This can be any value between `-1` to `1` in `0.1` increments, with `0` being the default. (default: 0, e.g. 0.4)
  --body-loop: int # The number of times to repeat the text the file, 0 for infinite (default: 1)
  --premium: string@bool-completer # Set to true to use the premium version of the specified style if available, otherwise the standard version will be used. The default value is false. You can find more information about Premium Voices in the [Text-To-Speech guide](/voice/voice-api/guides/text-to-speech#premium-voices). (default: false)
  --style: int # The vocal style (vocal range, tessitura, and timbre) to use (default: 0)
  text: string # The text to read (e.g. Hello. How are you today?)
  --voice-name: string@voice-name-completer # <strong>DEPRECATED</strong> The voice & language to use (DEPRECATED, default: Kimberly)
]: any -> record<message: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($uuid)/talk")
  let body = {language: $language, level: $level, loop: $body_loop, premium: $premium, style: $style, text: $text, voice_name: $voice_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
