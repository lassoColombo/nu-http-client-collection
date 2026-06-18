# Auto-generated client for Verify API v1.2.4
# Source: https://api.apis.guru/v2/specs/nexmo.com/verify/1.2.4/openapi.json
# Auth: --token flag or $env.VERIFY_API_TOKEN

const BASE_URL = "https://api.nexmo.com/verify"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VERIFY_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.nexmo.com/verify"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/xml"] }
def cmd-completer [] { ["cancel" "trigger_next_event"] }
def code-length-completer [] { ["4" "6"] }
def lg-completer [] { ["bg-bg" "cs-cz" "da-dk" "de-de" "ee-et" "el-gr" "en-gb" "es-es" "fi-fi" "fr-fr" "ga-ie" "hu-hu" "it-it" "lt-lt" "lv-lv" "mt-mt" "nl-nl" "pl-pl" "sk-sk" "sl-si" "sv-se"] }
def workflow-id-completer [] { ["1" "2" "3" "4" "5" "6" "7"] }
def lg-completer-1 [] { ["ar-xa" "cs-cz" "cy-cy" "cy-gb" "da-dk" "de-de" "el-gr" "en-au" "en-gb" "en-in" "en-us" "es-es" "es-mx" "es-us" "fi-fi" "fil-ph" "fr-ca" "fr-fr" "hi-in" "hu-hu" "id-id" "is-is" "it-it" "ja-jp" "ko-kr" "nb-no" "nl-nl" "pl-pl" "pt-br" "pt-pt" "ro-ro" "ru-ru" "sv-se" "th-th" "tr-tr" "vi-vn" "yue-cn" "zh-cn" "zh-tw"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "check verify" } } | get name | first)
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

# Verify Check
#
# POST /check/{format}
# operationId: verifyCheck
@deprecated --flag ip-address
export def "check verify" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  api_key: string # You can find your API key in your [account dashboard](https://dashboard.nexmo.com) (e.g. abcd1234)
  api_secret: string # You can find your API secret in your [account dashboard](https://dashboard.nexmo.com) (e.g. Sup3rS3cr3t!!)
  code: string # The verification code entered by your user. (e.g. 1234)
  --ip-address: string # (This field is no longer used) (DEPRECATED, e.g. 123.0.0.255)
  request_id: string # The Verify request to check. This is the `request_id` you received in the response to the Verify request. (e.g. abcdef0123456789abcdef0123456789)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/check/{format}"))
  let req_body = {"api_key": $api_key, "api_secret": $api_secret, "code": $code, "ip_address": $ip_address, "request_id": $request_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Verify Control
#
# POST /control/{format}
# operationId: verifyControl
export def "control verify" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  api_key: string # You can find your API key in your [account dashboard](https://dashboard.nexmo.com) (e.g. abcd1234)
  api_secret: string # You can find your API secret in your [account dashboard](https://dashboard.nexmo.com) (e.g. Sup3rS3cr3t!!)
  cmd: string@cmd-completer # The possible commands are `cancel` to request cancellation of the verification process, or `trigger_next_event` to advance to the next verification event (if any). Cancellation is only possible 30 seconds after the start of the verification request and before the second event (either TTS or SMS) has taken place. (e.g. cancel)
  request_id: string # The `request_id` you received in the response to the Verify request. (e.g. abcdef0123456789abcdef0123456789)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/control/{format}"))
  let req_body = {"api_key": $api_key, "api_secret": $api_secret, "cmd": $cmd, "request_id": $request_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Request a network unblock
#
# POST /network-unblock
# operationId: networkUnblock
export def "network-unblock create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --network: string # The Network code (e.g. 32526)
  --unblock-duration: int # An optional duration the unblock will be applied for in seconds (default: 3600, e.g. 3600)
]: any -> record<network: string, unblocked_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/network-unblock")
  let req_body = {"network": $network, "unblock_duration": $unblock_duration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PSD2 (Payment Services Directive 2) Request
#
# POST /psd2/{format}
# operationId: verifyRequestWithPSD2
export def "psd2 verify-request" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # The decimal amount of the payment to be confirmed, in Euros (format: float, e.g. 48.00)
  api_key: string # You can find your API key in your [account dashboard](https://dashboard.nexmo.com) (e.g. abcd1234)
  api_secret: string # You can find your API secret in your [account dashboard](https://dashboard.nexmo.com) (e.g. Sup3rS3cr3t!!)
  --code-length: int@code-length-completer # The length of the verification code. (default: 4, e.g. 6)
  --country: string # If you do not provide `number` in international format or you are not sure if `number` is correctly formatted, specify the two-character country code in `country`. Verify will then format the number for you. (e.g. GB)
  --lg: string@lg-completer # By default, the SMS or text-to-speech (TTS) message is generated in the locale that matches the `number`. For example, the text message or TTS message for a `33*` number is sent in French. Use this parameter to explicitly control the language used. *Note: Voice calls in English for `bg-bg`, `ee-et`, `ga-ie`, `lv-lv`, `lt-lt`, `mt-mt`, `sk-sk`, `sk-si` (default: en-gb, e.g. es-es)
  --next-event-wait: int # Specifies the wait time in seconds between attempts to deliver the verification code. (default: 300, e.g. 120)
  number: string # The mobile or landline phone number to verify. Unless you are setting `country` explicitly, this number must be in [E.164](https://en.wikipedia.org/wiki/E.164) format. (e.g. 447700900000)
  payee: string # An alphanumeric string to indicate to the user the name of the recipient that they are confirming a payment to. (e.g. Acme Inc)
  --pin-expiry: int # How long the generated verification code is valid for, in seconds. When you specify both `pin_expiry` and `next_event_wait` then `pin_expiry` must be an integer multiple of `next_event_wait` otherwise `pin_expiry` is defaulted to equal next_event_wait. See [changing the event timings](https://developer.nexmo.com/verify/guides/changing-default-timings). (default: 300, e.g. 240)
  --workflow-id: int@workflow-id-completer # Selects the predefined sequence of SMS and TTS (Text To Speech) actions to use in order to convey the PIN to your user. For example, an id of 1 identifies the workflow SMS - TTS - TTS. For a list of all workflows and their associated ids, please visit the [developer portal](https://developer.nexmo.com/verify/guides/workflows-and-events). (default: 1, e.g. 4)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/psd2/{format}"))
  let req_body = {"amount": $amount, "api_key": $api_key, "api_secret": $api_secret, "code_length": $code_length, "country": $country, "lg": $lg, "next_event_wait": $next_event_wait, "number": $number, "payee": $payee, "pin_expiry": $pin_expiry, "workflow_id": $workflow_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Verify Search
#
# GET /search/{format}
# operationId: verifySearch
export def "search verify" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-key: string # e.g. abcd1234
  --api-secret: string # e.g. Sup3rS3cr3t!!
  --request-id: string # The `request_id` you received in the Verify Request Response. Required if `request_ids` not provided. (e.g. abcdef0123456789abcdef0123456789)
  --request-ids: list<string> # More than one `request_id`. Each `request_id` is a new parameter in the Verify Search request. Required if `request_id` not provided.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "api_secret" $api_secret "scalar") (serialize-qp "request_id" $request_id "scalar") (serialize-qp "request_ids" $request_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/search/{format}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request a Verification
#
# POST /{format}
# operationId: verifyRequest
export def "requests verify" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  api_key: string # You can find your API key in your [account dashboard](https://dashboard.nexmo.com) (e.g. abcd1234)
  api_secret: string # You can find your API secret in your [account dashboard](https://dashboard.nexmo.com) (e.g. Sup3rS3cr3t!!)
  brand: string # An 18-character alphanumeric string you can use to personalize the verification request SMS body, to help users identify your company or application name. For example: "Your `Acme Inc` PIN is ..." (e.g. Acme Inc)
  --code-length: int@code-length-completer # The length of the verification code. (default: 4, e.g. 6)
  --country: string # If you do not provide `number` in international format or you are not sure if `number` is correctly formatted, specify the two-character country code in `country`. Verify will then format the number for you. (e.g. GB)
  --lg: string@lg-completer-1 # By default, the SMS or text-to-speech (TTS) message is generated in the locale that matches the `number`. For example, the text message or TTS message for a `33*` number is sent in French. Use this parameter to explicitly control the language used for the Verify request. A list of languages is available: <https://developer.nexmo.com/verify/guides/verify-languages> (default: en-us, e.g. en-us)
  --next-event-wait: int # Specifies the wait time in seconds between attempts to deliver the verification code. (default: 300, e.g. 120)
  number: string # The mobile or landline phone number to verify. Unless you are setting `country` explicitly, this number must be in [E.164](https://en.wikipedia.org/wiki/E.164) format. (e.g. 447700900000)
  --pin-code: string # A custom PIN to send to the user. If a PIN is not provided, Verify will generate a random PIN for you. This feature is not enabled by default - please discuss with your Account Manager if you would like it enabled. If this feature is not enabled on your account, error status `20` will be returned. (e.g. AKFG-3424)
  --pin-expiry: int # How long the generated verification code is valid for, in seconds. When you specify both `pin_expiry` and `next_event_wait` then `pin_expiry` must be an integer multiple of `next_event_wait` otherwise `pin_expiry` is defaulted to equal next_event_wait. See [changing the event timings](https://developer.nexmo.com/verify/guides/changing-default-timings). (default: 300, e.g. 240)
  --sender-id: string # An 11-character alphanumeric string that represents the [identity of the sender](https://developer.nexmo.com/messaging/sms/guides/custom-sender-id) of the verification request. Depending on the destination of the phone number you are sending the verification SMS to, restrictions might apply. (default: VERIFY, e.g. ACME)
  --workflow-id: int@workflow-id-completer # Selects the predefined sequence of SMS and TTS (Text To Speech) actions to use in order to convey the PIN to your user. For example, an id of 1 identifies the workflow SMS - TTS - TTS. For a list of all workflows and their associated ids, please visit the [developer portal](https://developer.nexmo.com/verify/guides/workflows-and-events). (default: 1, e.g. 4)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}"))
  let req_body = {"api_key": $api_key, "api_secret": $api_secret, "brand": $brand, "code_length": $code_length, "country": $country, "lg": $lg, "next_event_wait": $next_event_wait, "number": $number, "pin_code": $pin_code, "pin_expiry": $pin_expiry, "sender_id": $sender_id, "workflow_id": $workflow_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}
